-- Flexible starter taxonomy and category-specific fields. Users may add their own categories.
insert into collection.registro_fonti_categorie (nome, schema_campi, origine_configurazione)
select v.nome, v.schema_campi::jsonb, 'sistema'
from (values
('Orologi e orologeria', '[{"key":"marchio","label":"Marchio","type":"text"},{"key":"referenza","label":"Referenza","type":"text"},{"key":"movimento","label":"Movimento","type":"text"},{"key":"materiali","label":"Materiali","type":"text"},{"key":"edizione","label":"Edizione / variante","type":"text"},{"key":"corredo","label":"Scatola e documenti","type":"text"}]'),
('Costruzioni e mattoncini', '[{"key":"codice_set","label":"Codice set","type":"text"},{"key":"pezzi","label":"Numero pezzi","type":"number"},{"key":"minifigure","label":"Minifigure","type":"text"},{"key":"edizione","label":"Edizione / variante","type":"text"}]'),
('Fumetti e manga', '[{"key":"editore","label":"Editore","type":"text"},{"key":"serie","label":"Serie","type":"text"},{"key":"numero_albo","label":"Numero albo / volume","type":"text"},{"key":"isbn","label":"ISBN","type":"text"},{"key":"lingua","label":"Lingua / mercato","type":"text"},{"key":"edizione","label":"Edizione","type":"text"}]'),
('Action figures e statue', '[{"key":"produttore","label":"Produttore","type":"text"},{"key":"linea","label":"Linea","type":"text"},{"key":"scala","label":"Scala / dimensione","type":"text"},{"key":"materiale","label":"Materiale","type":"text"},{"key":"edizione","label":"Edizione / variante","type":"text"}]'),
('Die-cast e modellismo', '[{"key":"produttore","label":"Produttore","type":"text"},{"key":"scala","label":"Scala","type":"text"},{"key":"codice_modello","label":"Codice modello","type":"text"},{"key":"materiale","label":"Materiale","type":"text"},{"key":"confezione","label":"Confezione","type":"text"}]'),
('Musica e supporti', '[{"key":"artista","label":"Artista","type":"text"},{"key":"titolo","label":"Titolo","type":"text"},{"key":"formato","label":"Formato","type":"text"},{"key":"catalog_number","label":"Numero di catalogo","type":"text"},{"key":"paese","label":"Paese / edizione","type":"text"},{"key":"anno","label":"Anno edizione","type":"number"}]'),
('Numismatica e filatelia', '[{"key":"paese","label":"Paese","type":"text"},{"key":"anno","label":"Anno","type":"number"},{"key":"valore_facciale","label":"Valore facciale","type":"text"},{"key":"materiale","label":"Materiale","type":"text"},{"key":"grado","label":"Grado / conservazione","type":"text"}]'),
('Trading cards', '[{"key":"gioco","label":"Gioco / serie","type":"text"},{"key":"numero_carta","label":"Numero carta","type":"text"},{"key":"rarita","label":"Rarità","type":"text"},{"key":"lingua","label":"Lingua","type":"text"},{"key":"grado","label":"Grado / certificazione","type":"text"}]'),
('Libri e prime edizioni', '[{"key":"autore","label":"Autore","type":"text"},{"key":"editore","label":"Editore","type":"text"},{"key":"isbn","label":"ISBN","type":"text"},{"key":"edizione","label":"Edizione / stampa","type":"text"},{"key":"lingua","label":"Lingua","type":"text"}]'),
('Arte e memorabilia', '[{"key":"autore","label":"Autore / artista","type":"text"},{"key":"provenienza","label":"Provenienza","type":"text"},{"key":"certificato","label":"Certificato / autenticazione","type":"text"},{"key":"materiali","label":"Materiali","type":"text"},{"key":"edizione","label":"Edizione / tiratura","type":"text"}]'),
('Altra collezione', '[{"key":"identificativo","label":"Identificativo specialistico","type":"text"},{"key":"variante","label":"Variante","type":"text"},{"key":"provenienza","label":"Provenienza","type":"text"},{"key":"note_specialistiche","label":"Note specialistiche","type":"text"}]')
) as v(nome,schema_campi)
where not exists (
  select 1 from collection.registro_fonti_categorie c
  where c.nome = v.nome and c.origine_configurazione = 'sistema'
);
