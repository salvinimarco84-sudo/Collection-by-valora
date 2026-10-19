-- PR-12 TEST: fine-wine auction price history sources.
-- Idempotent. Auction data must be tagged separately from current asking prices.
insert into collection.registro_fonti
(nome,url_base,ambito,categoria,marchio_editore,franchise,mercato,tipo_fonte,priorita,attendibilita_dichiarata,stato_verifica,origine_configurazione,condivisa,attiva,note)
select v.nome,v.url_base,v.ambito,v.categoria,v.marchio_editore,v.franchise,v.mercato,v.tipo_fonte,v.priorita,v.attendibilita_dichiarata,'da_verificare','sistema',true,true,v.note
from (values
('iDealwine Price Estimate','https://www.idealwine.com/en/cote','stima basata su prezzi d asta storici','vino e bottiglie pregiate','iDealwine','vini; produttori; annate; formati','globale','mercato',1,'alta','La fonte dichiara un database di prezzi d asta storici e aggiornamento settimanale; annotare se il dato include commissioni'),
('CultX Wine Auction Results','https://www.cultx.com/learn/articles/wine-auction-results','aggregatore di risultati d asta realizzati','vino e bottiglie pregiate','CultX','vini pregiati; annate; lotti conclusi','globale','mercato',1,'alta','Aggrega risultati realizzati da più case d asta; registrare la casa d asta originale e la data del lotto'),
('Acker Wine Analytics','https://www.ackerwines.com/wine-analytics/','archivio e analisi prezzi d asta','vino e bottiglie pregiate','Acker Wines','fine wine; annate; lotti conclusi','globale','mercato',2,'alta','Parte dell archivio analitico è riservata agli utenti registrati'),
('Sothebys Wine Auction Results','https://www.sothebys.com/en/results','risultati aste e lotti conclusi','vino e bottiglie pregiate','Sothebys','fine wine; lotti; annate; formati','globale','mercato',2,'alta','Verificare i prezzi finali e le note su premi, tasse e costi; alcuni risultati richiedono login')
) as v(nome,url_base,ambito,categoria,marchio_editore,franchise,mercato,tipo_fonte,priorita,attendibilita_dichiarata,note)
where not exists (select 1 from collection.registro_fonti f where lower(f.nome)=lower(v.nome) and f.url_base=v.url_base);
