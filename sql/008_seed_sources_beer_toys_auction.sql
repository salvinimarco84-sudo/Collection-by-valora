-- PR-12 TEST: supplementary specialist sources for beer collectibles and toys.
-- Idempotent; keep all new sources unverified until actual source checks complete.
insert into collection.registro_fonti
(nome,url_base,ambito,categoria,marchio_editore,franchise,mercato,tipo_fonte,priorita,attendibilita_dichiarata,stato_verifica,origine_configurazione,condivisa,attiva,note)
select v.nome,v.url_base,v.ambito,v.categoria,v.marchio_editore,v.franchise,v.mercato,v.tipo_fonte,v.priorita,v.attendibilita_dichiarata,'da_verificare','sistema',true,true,v.note
from (values
('BCCA Breweriana Collectibles Database','https://bcca-usbc.com/','catalogo storico lattine e breweriana','birre e birre da collezione','BCCA','lattine birra; birrifici; breweriana','globale','specialistica',1,'alta','Cataloghi specialistici con identificativi, immagini e varianti per lattine da collezione'),
('MySteinCollection','https://mysteincollection.com/','catalogo boccali da collezione','birre e birre da collezione','MySteinCollection','boccali birra; steins','globale','specialistica',2,'alta','Archivio immagini e identificativi per boccali antichi e da collezione'),
('The Toys Database','https://toys.thepreservationnetwork.org/','catalogo e identificazione giocattoli','giocattoli da collezione','The Preservation Network','giocattoli vintage; action figure; veicoli; bambole','globale','specialistica',1,'alta','Catalogo esteso di giocattoli e produttori, utile per identificazione e varianti'),
('Catawiki','https://www.catawiki.com/','aste e prezzi di realizzo osservabili','vino e bottiglie pregiate','Catawiki','vini; champagne; bottiglie da collezione','Europa','mercato',3,'media','Usare lotti conclusi quando visibili; distinguere prezzo finale, commissioni e prezzo richiesto')
) as v(nome,url_base,ambito,categoria,marchio_editore,franchise,mercato,tipo_fonte,priorita,attendibilita_dichiarata,note)
where not exists (select 1 from collection.registro_fonti f where lower(f.nome)=lower(v.nome) and f.url_base=v.url_base);
