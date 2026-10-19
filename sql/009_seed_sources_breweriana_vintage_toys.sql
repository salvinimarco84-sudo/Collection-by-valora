-- PR-12 TEST source expansion: breweriana, vintage toy catalogs and franchise databases.
-- Idempotent; new sources remain unverified until search/runtime validation.
insert into collection.registro_fonti
(nome,url_base,ambito,categoria,marchio_editore,franchise,mercato,tipo_fonte,priorita,attendibilita_dichiarata,stato_verifica,origine_configurazione,condivisa,attiva,note)
select v.nome,v.url_base,v.ambito,v.categoria,v.marchio_editore,v.franchise,v.mercato,v.tipo_fonte,v.priorita,v.attendibilita_dichiarata,'da_verificare','sistema',true,true,v.note
from (values
('BCCA USBC Online Supplement','https://bcca-usbc.com/','catalogo identificazione lattine e varianti','birre e birre da collezione','BCCA','lattine birra; breweriana; varianti; identificativi USBC','globale','specialistica',1,'alta','Catalogo con identificativi, immagini e dettagli per varianti di lattine; non è da solo una fonte di prezzi di realizzo'),
('Breweriana.com Sold and In-Stock Search','https://www.breweriana.com/search/','ricerca collezionismo e storico prezzi','birre e birre da collezione','Breweriana.com','lattine; insegne; pubblicità birrifici; breweriana','globale','mercato',2,'alta','Distinguere gli oggetti venduti da quelli ancora in vendita e verificare data e stato del lotto'),
('ToyVault','https://toyvault.app/','database comunitario giocattoli vintage','giocattoli da collezione','ToyVault','linee vintage; varianti; uscite regionali','globale','specialistica',2,'media','Catalogo comunitario utile per identificazione; verificare copertura e fonti delle singole schede'),
('Star Wars Database','https://www.starwarsdatabase.com/','catalogo giocattoli e collezionabili Star Wars','giocattoli da collezione','Star Wars Database','Star Wars vintage; figure; veicoli; varianti; accessori','globale','specialistica',1,'alta','Record con produttore, anno, numero di catalogo, UPC e foto quando disponibili'),
('Vintage Toy Catalog','https://www.vintagetoycatalog.com/','catalogo giocattoli vintage e linee','giocattoli da collezione','Vintage Toy Catalog','figure vintage; linee giocattolo; varianti','globale','specialistica',3,'media','Fonte emergente; convalidare stabilità, copertura e accuratezza prima di usarla per valutazioni')
) as v(nome,url_base,ambito,categoria,marchio_editore,franchise,mercato,tipo_fonte,priorita,attendibilita_dichiarata,note)
where not exists (select 1 from collection.registro_fonti f where lower(f.nome)=lower(v.nome) and f.url_base=v.url_base);
