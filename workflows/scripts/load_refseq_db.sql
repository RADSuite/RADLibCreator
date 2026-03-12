.mode tabs
.import temp.tsv all_data

CREATE TABLE accessionTaxa AS
SELECT DISTINCT "Organism Taxonomic ID" AS "taxa", "Assembly Accession" AS "accession"
FROM all_data;

CREATE TABLE names AS
SELECT DISTINCT "Organism Taxonomic ID" AS "id", "Organism name" AS "name"
FROM all_data;

DROP TABLE all_data;