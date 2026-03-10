.mode tabs
.import temp.tsv unfiltered

CREATE TABLE filtered AS
SELECT *
FROM unfiltered
WHERE "WGS URL" != "";

DROP TABLE unfiltered;

CREATE TABLE accessionTaxa AS
SELECT DISTINCT "Organism Taxonomic ID" AS "taxa", "Assembly Accession" AS "accession"
FROM filtered;

CREATE TABLE names AS
SELECT DISTINCT "Organism Taxonomic ID" AS "id", "Organism name" AS "name"
FROM filtered;

