-- Initial source registry for the TEST environment. Users can extend it.
insert into collection.registro_fonti
(nome,url_base,ambito,categoria,marchio_editore,franchise,mercato,tipo_fonte,priorita,attendibilita_dichiarata,stato_verifica,origine_configurazione,condivisa,note)
select v.nome,v.url_base,v.ambito,v.categoria,v.marchio_editore,v.franchise,v.mercato,v.tipo_fonte,v.priorita,v.attendibilita_dichiarata,v.stato_verifica,'sistema',true,v.note
from (values
('LEGO ufficiale','https://www.lego.com/','prodotti','costruzioni','LEGO','LEGO','globale','ufficiale',1,'ufficiale','da_verificare','Catalogo ufficiale; verificare la copertura dei singoli set'),
('BrickLink','https://www.bricklink.com/','catalogo e mercato','costruzioni','LEGO','LEGO','globale','specialistica',2,'alta','da_verificare','Fonte specialistica prioritaria per set, pezzi e codici'),
('Rebrickable','https://rebrickable.com/','catalogo','costruzioni','LEGO','LEGO','globale','specialistica',3,'alta','da_verificare','Fonte aggiuntiva per set e componenti'),
('Hasbro Pulse','https://www.hasbropulse.com/eu/it/','prodotti','action figure','Hasbro','Transformers; G.I. Joe; Marvel Legends','Europa','ufficiale',1,'ufficiale','da_verificare','Catalogo ufficiale Hasbro per linee disponibili'),
('Hasbro','https://www.hasbro.com/','prodotti','giocattoli','Hasbro','Transformers; G.I. Joe; Marvel','globale','ufficiale',2,'ufficiale','da_verificare','Fonte istituzionale del produttore'),
('Mattel','https://shop.mattel.com/pages/all-brands','prodotti','giocattoli','Mattel','Barbie; Hot Wheels; Matchbox','globale','ufficiale',1,'ufficiale','da_verificare','Pagina ufficiale dei marchi Mattel'),
('Mattel supporto','https://service.mattel.com/','assistenza e identificazione','giocattoli','Mattel','Hot Wheels; Barbie; Matchbox','globale','ufficiale',2,'ufficiale','da_verificare','Supporto e identificazione prodotto'),
('Bandai','https://www.bandai.com/','prodotti','figure e giocattoli','Bandai','Bandai','globale','ufficiale',1,'ufficiale','da_verificare','Catalogo ufficiale Bandai, verificare linea e regione'),
('TAMASHII WEB','https://tamashiiweb.com/','prodotti','figure da collezione','Bandai Spirits','Saint Cloth Myth; anime figures','globale','ufficiale',1,'ufficiale','da_verificare','Fonte ufficiale per specifiche linee di figure'),
('Rolex','https://www.rolex.com/','prodotti e documentazione','orologi','Rolex','Rolex','globale','ufficiale',1,'ufficiale','da_verificare','Fonte primaria per informazioni ufficiali; non basta da sola a autenticare un esemplare'),
('Swatch','https://www.swatch.com/','prodotti','orologi','Swatch','Swatch','globale','ufficiale',1,'ufficiale','da_verificare','Catalogo ufficiale e collezioni Swatch'),
('Omega','https://www.omegawatches.com/','prodotti e storia','orologi','Omega','Omega','globale','ufficiale',1,'ufficiale','da_verificare','Fonte primaria per modelli e storia del marchio'),
('Panini Comics Italia','https://www.panini.it/','catalogo editoriale','fumetti','Panini Comics','fumetti','Italia','ufficiale',1,'ufficiale','da_verificare','Edizioni italiane e catalogo editoriale'),
('SaldaPress','https://www.saldapress.com/','catalogo editoriale','fumetti','SaldaPress','fumetti','Italia','ufficiale',1,'ufficiale','da_verificare','Catalogo italiano e dati edizione'),
('Sergio Bonelli Editore','https://www.sergiobonelli.it/','catalogo editoriale','fumetti','Sergio Bonelli Editore','fumetti','Italia','ufficiale',1,'ufficiale','da_verificare','Catalogo ufficiale e serie'),
('Star Comics','https://www.starcomics.com/','catalogo editoriale','fumetti e manga','Star Comics','fumetti; manga','Italia','ufficiale',1,'ufficiale','da_verificare','Catalogo ufficiale italiano'),
('J-POP Manga','https://www.j-pop.it/','catalogo editoriale','manga','J-POP Manga','manga','Italia','ufficiale',1,'ufficiale','da_verificare','Catalogo edizioni italiane'),
('BAO Publishing','https://baopublishing.it/','catalogo editoriale','fumetti','BAO Publishing','fumetti','Italia','ufficiale',1,'ufficiale','da_verificare','Catalogo editoriale italiano'),
('Bandai Hobby','https://bandai-hobby.net/','prodotti','modellismo','Bandai','Gundam; Gunpla','Giappone','ufficiale',1,'ufficiale','da_verificare','Fonte ufficiale per prodotti hobby; verificare disponibilità regionale')
) as v(nome,url_base,ambito,categoria,marchio_editore,franchise,mercato,tipo_fonte,priorita,attendibilita_dichiarata,stato_verifica,note)
where not exists (
  select 1 from collection.registro_fonti f
  where lower(f.nome)=lower(v.nome) and f.url_base=v.url_base and f.origine_configurazione='sistema'
);
