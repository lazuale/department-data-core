BEGIN;

SET LOCAL ROLE ddc_owner;

CREATE SCHEMA meta AUTHORIZATION ddc_owner;
CREATE SCHEMA raw  AUTHORIZATION ddc_owner;
CREATE SCHEMA stg  AUTHORIZATION ddc_owner;
CREATE SCHEMA xref AUTHORIZATION ddc_owner;
CREATE SCHEMA core AUTHORIZATION ddc_owner;
CREATE SCHEMA ops  AUTHORIZATION ddc_owner;
CREATE SCHEMA etl  AUTHORIZATION ddc_owner;
CREATE SCHEMA api  AUTHORIZATION ddc_owner;
CREATE SCHEMA mart AUTHORIZATION ddc_owner;

CREATE TABLE meta.schema_migration
(
    migration_id text        NOT NULL,
    applied_at   timestamptz NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT pk_schema_migration
        PRIMARY KEY (migration_id)
);

INSERT INTO meta.schema_migration (migration_id)
VALUES ('0001_initial');

COMMIT;
