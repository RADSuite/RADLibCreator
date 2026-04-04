.mode tabs
.import temp.tsv all_data

-- Better import block
-- sqlite> .mode ascii
-- sqlite> .separator ";" "\n"
-- sqlite> .import input.csv MyTable

-- Make sure all data in Assembly Accession are accessions
CREATE TABLE filtered_data AS
SELECT *
FROM all_data
WHERE "Assembly Accession" LIKE 'GCF%'
AND "Assembly Accession" IS NOT NULL;


CREATE TABLE accessionTaxa AS
SELECT DISTINCT "Organism Taxonomic ID" AS "taxa", "Assembly Accession" AS "accession"
FROM filtered_data;

CREATE TABLE names AS
SELECT DISTINCT "Organism Taxonomic ID" AS "id", "Organism name" AS "name"
FROM filtered_data;

DROP TABLE all_data;
DROP TABLE filtered_data;
