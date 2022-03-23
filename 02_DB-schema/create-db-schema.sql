--------------------------------------
--                                  --
--      IDS project - 2nd part      --
--                                  --
-- Author: Michal Šmahel (xsmahe01) --
-- Author: Martin Havlík (xhavli56) --
-- Date: March 2022                 --
--------------------------------------


------------------------------------------------------------------------------------------------------------------ RESET
-- DROP TABLE my_table CASCADE CONSTRAINTS;


----------------------------------------------------------------------------------------------------------------- TABLES
-- my_table
-- CREATE TABLE my_table (
--     id INTEGER,
--     col VARCHAR(20) NOT NULL
-- )


------------------------------------------------------------------------------------------------------------ CONSTRAINTS
-- Primary keys
-- ALTER TABLE my_table ADD CONSTRAINT pk_my_table_id PRIMARY KEY (id);

-- Foreign keys
-- ALTER TABLE my_table ADD CONSTRAINT fk_my_table_other_table_col FOREIGN KEY (col) REFERENCES other_table (name);
