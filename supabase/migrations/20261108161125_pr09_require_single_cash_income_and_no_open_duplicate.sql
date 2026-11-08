-- PR-09: require exactly one original cash inflow and prevent duplicate open sale cycles.

CREATE OR REPLACE FUNCTION collection.pr_annulla_vendita(p_codice_vendita bigint, p_rimetti_in_vendita boolean)
 RETURNS TABLE(codice_vendita bigint, codice_oggetto bigint, stato_vendita character varying, stato_oggetto character varying, codice_nuova_vendita_aperta bigint, rimessa_in_vendita boolean)
 LANGUAGE plpgsql
 SET search_path TO 'collection', 'pg_temp'
AS $function$
DECLARE
    v_codice_oggetto BIGINT;
    v_codice_ciclo BIGINT;
    v_descrizione TEXT;
    v_data_vendita DATE;
    v_importo NUMERIC(14,2);
    v_valuta CHAR(3);
    v_codice_piattaforma BIGINT;
    v_canale TEXT;
    v_note_vendita TEXT;
    v_stato_vendita VARCHAR(12);
    v_stato_oggetto VARCHAR(20);
    v_destinazione VARCHAR(20);
    v_num_incassi INTEGER := 0;
    v_data_inizio DATE;
    v_prezzo NUMERIC(14,2);
    v_note_ciclo TEXT;
    v_nuovo_ciclo BIGINT;
    v_piattaforma BIGINT;
BEGIN
    IF p_codice_vendita IS NULL OR p_codice_vendita <= 0 THEN
        RAISE EXCEPTION 'PR-08: codice vendita obbligatorio e valido.';
    END IF;

    IF p_rimetti_in_vendita IS NULL THEN
        RAISE EXCEPTION 'PR-08: indicare se rimettere l''oggetto in vendita.';
    END IF;

    SELECT mv.codice_oggetto, mv.codice_vendita_aperta,
           mv.descrizione_oggetto, mv.data_vendita, mv.importo_vendita,
           mv.valuta, mv.codice_piattaforma, mv.canale_effettivo,
           mv.note, mv.stato_vendita
      INTO v_codice_oggetto, v_codice_ciclo, v_descrizione,
           v_data_vendita, v_importo, v_valuta, v_codice_piattaforma,
           v_canale, v_note_vendita, v_stato_vendita
      FROM collection.master_vendite mv
     WHERE mv.codice_vendita = p_codice_vendita
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PR-08: vendita % inesistente.', p_codice_vendita;
    END IF;

    IF v_stato_vendita <> 'CONCLUSA' THEN
        RAISE EXCEPTION 'PR-08: la vendita % non è CONCLUSA oppure è già stata annullata.', p_codice_vendita;
    END IF;

    SELECT mo.stato, mo.destinazione
      INTO v_stato_oggetto, v_destinazione
      FROM collection.master_oggetti mo
     WHERE mo.codice_oggetto = v_codice_oggetto
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PR-08: oggetto % inesistente.', v_codice_oggetto;
    END IF;

    IF v_stato_oggetto <> 'VENDUTO' THEN
        RAISE EXCEPTION 'PR-08: l''oggetto % non risulta VENDUTO; annullamento bloccato.', v_codice_oggetto;
    END IF;

    -- L'annullamento è ammesso solo quando esiste un unico incasso originario.
    SELECT count(*) INTO v_num_incassi
      FROM collection.cassa AS c
     WHERE c.codice_vendita = p_codice_vendita
       AND c.tipo_movimento = 'VENDITA'
       AND c.tipologia = 'ENTRATA';

    IF v_num_incassi <> 1 THEN
        RAISE EXCEPTION 'PR-09: atteso un solo incasso originario per la vendita %, trovati %.',
            p_codice_vendita, v_num_incassi;
    END IF;

    PERFORM 1
      FROM collection.cassa AS c
     WHERE c.codice_vendita = p_codice_vendita
       AND c.tipo_movimento = 'VENDITA'
       AND c.tipologia = 'ENTRATA'
       AND c.importo = v_importo
       AND c.valuta = v_valuta
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PR-09: importo o valuta dell''incasso non coerenti con la vendita %.', p_codice_vendita;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM collection.cassa AS c
         WHERE c.codice_vendita = p_codice_vendita
           AND c.tipo_movimento = 'VENDITA ANNULLATA'
    ) THEN
        RAISE EXCEPTION 'PR-08: esiste già un movimento compensativo per la vendita %.', p_codice_vendita;
    END IF;

    SELECT oiv.data_inizio_vendita, oiv.prezzo_di_vendita, oiv.note
      INTO v_data_inizio, v_prezzo, v_note_ciclo
      FROM collection.master_oggetti_in_vendita AS oiv
     WHERE oiv.codice_vendita_aperta = v_codice_ciclo
       AND oiv.codice_oggetto = v_codice_oggetto
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PR-08: ciclo originario di vendita non trovato.';
    END IF;

    IF p_rimetti_in_vendita THEN
        IF EXISTS (
            SELECT 1
              FROM collection.master_oggetti_in_vendita oiv
             WHERE oiv.codice_oggetto = v_codice_oggetto
               AND oiv.stato_ciclo_vendita = 'APERTO'
        ) THEN
            RAISE EXCEPTION 'PR-09: esiste già un ciclo di vendita aperto per l''oggetto %.', v_codice_oggetto;
        END IF;
        IF v_prezzo IS NULL OR v_prezzo <= 0 THEN
            RAISE EXCEPTION 'PR-08: prezzo del ciclo originario non valido.';
        END IF;
        IF NOT EXISTS (
            SELECT 1
              FROM collection.oggetti_in_vendita_piattaforme AS op
             WHERE op.codice_vendita_aperta = v_codice_ciclo
        ) THEN
            RAISE EXCEPTION 'PR-08: nessuna piattaforma associata al ciclo originario; impossibile ricreare la vendita senza conferma dei nuovi dati.';
        END IF;
    END IF;

    -- Aggiorna lo stato logico della vendita, senza cancellarla.
    UPDATE collection.master_vendite AS mv
       SET stato_vendita = 'ANNULLATA'
     WHERE mv.codice_vendita = p_codice_vendita;

    INSERT INTO collection.cassa
        (data, descrizione, tipo_movimento, importo, valuta, tipologia,
         codice_piattaforma, codice_vendita)
    VALUES
        (CURRENT_DATE,
         'Annullamento vendita ' || p_codice_vendita || ' - oggetto ' || v_codice_oggetto,
         'VENDITA ANNULLATA', v_importo, v_valuta, 'USCITA',
         v_codice_piattaforma, p_codice_vendita);

    INSERT INTO collection.storico
        (data_evento, codice_oggetto, codice_vendita, codice_vendita_aperta,
         tipo_evento, origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
    VALUES
        (CURRENT_DATE, v_codice_oggetto, p_codice_vendita, v_codice_ciclo,
         'ANNULLAMENTO', 'ANNULLA VENDITA', 'stato_vendita', 'CONCLUSA', 'ANNULLATA',
         'Vendita annullata; incasso compensato in cassa');

    IF p_rimetti_in_vendita THEN
        -- Il ciclo originario è già CHIUSO dalla PR-07; resta immutato.

        INSERT INTO collection.master_oggetti_in_vendita
            (codice_oggetto, descrizione_oggetto, data_inizio_vendita,
             prezzo_di_vendita, valuta, note, stato_ciclo_vendita)
        VALUES
            (v_codice_oggetto, v_descrizione, CURRENT_DATE,
             v_prezzo, v_valuta, v_note_ciclo, 'APERTO')
        RETURNING master_oggetti_in_vendita.codice_vendita_aperta
             INTO v_nuovo_ciclo;

        FOR v_piattaforma IN
            SELECT codice_piattaforma
              FROM collection.oggetti_in_vendita_piattaforme
             WHERE codice_vendita_aperta = v_codice_ciclo
             ORDER BY codice_piattaforma
        LOOP
            INSERT INTO collection.oggetti_in_vendita_piattaforme
                (codice_vendita_aperta, codice_oggetto, descrizione_oggetto, codice_piattaforma)
            VALUES
                (v_nuovo_ciclo, v_codice_oggetto, v_descrizione, v_piattaforma);
        END LOOP;

        UPDATE collection.master_oggetti AS mo
           SET stato = 'IN VENDITA',
               destinazione = 'RIVENDITA'
         WHERE mo.codice_oggetto = v_codice_oggetto;

        INSERT INTO collection.storico
            (data_evento, codice_oggetto, codice_vendita_aperta,
             tipo_evento, origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
        VALUES
            (CURRENT_DATE, v_codice_oggetto, v_nuovo_ciclo,
             'APERTURA_VENDITA', 'ANNULLA VENDITA', 'stato_ciclo_vendita', NULL, 'APERTO',
             'Nuovo ciclo aperto dopo annullamento; dati di vendita ripresi dal ciclo originario'),
            (CURRENT_DATE, v_codice_oggetto, v_nuovo_ciclo,
             'CAMBIO_STATO', 'ANNULLA VENDITA', 'stato', 'VENDUTO', 'IN VENDITA',
             'Oggetto rimesso in vendita dopo annullamento');
        IF v_destinazione IS DISTINCT FROM 'RIVENDITA' THEN
            INSERT INTO collection.storico
                (data_evento, codice_oggetto, codice_vendita_aperta, tipo_evento,
                 origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
            VALUES
                (CURRENT_DATE, v_codice_oggetto, v_nuovo_ciclo, 'CAMBIO_DESTINAZIONE',
                 'ANNULLA VENDITA', 'destinazione', v_destinazione, 'RIVENDITA',
                 'Destinazione aggiornata dopo annullamento con rimessa in vendita');
        END IF;
        v_stato_oggetto := 'IN VENDITA';
    ELSE
        UPDATE collection.master_oggetti AS mo
           SET stato = 'DISPONIBILE',
               destinazione = 'COLLEZIONE'
         WHERE mo.codice_oggetto = v_codice_oggetto;

        INSERT INTO collection.storico
            (data_evento, codice_oggetto, codice_vendita_aperta,
             tipo_evento, origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
        VALUES
            (CURRENT_DATE, v_codice_oggetto, v_codice_ciclo,
             'CAMBIO_STATO', 'ANNULLA VENDITA', 'stato', 'VENDUTO', 'DISPONIBILE',
             'Oggetto reso disponibile dopo annullamento della vendita');
        IF v_destinazione IS DISTINCT FROM 'COLLEZIONE' THEN
            INSERT INTO collection.storico
                (data_evento, codice_oggetto, codice_vendita_aperta, tipo_evento,
                 origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
            VALUES
                (CURRENT_DATE, v_codice_oggetto, v_codice_ciclo, 'CAMBIO_DESTINAZIONE',
                 'ANNULLA VENDITA', 'destinazione', v_destinazione, 'COLLEZIONE',
                 'Destinazione aggiornata dopo annullamento e ritorno in collezione');
        END IF;
        v_stato_oggetto := 'DISPONIBILE';
        v_nuovo_ciclo := NULL;
    END IF;

    codice_vendita := p_codice_vendita;
    codice_oggetto := v_codice_oggetto;
    stato_vendita := 'ANNULLATA';
    stato_oggetto := v_stato_oggetto;
    codice_nuova_vendita_aperta := v_nuovo_ciclo;
    rimessa_in_vendita := p_rimetti_in_vendita;
    RETURN NEXT;
END;
$function$
;
