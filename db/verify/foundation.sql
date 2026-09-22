DO $$
DECLARE
    role_name text;
    schema_name text;
    actual_owner text;
    schema_migration_oid regclass;
BEGIN
    FOREACH role_name IN ARRAY ARRAY[
        'ddc_owner',
        'ddc_loader',
        'ddc_worker',
        'ddc_analyst'
    ]
    LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM pg_roles
            WHERE rolname = role_name
        ) THEN
            RAISE EXCEPTION 'Роль % отсутствует', role_name;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM pg_roles
            WHERE rolname = role_name
              AND (
                  rolcanlogin
                  OR rolsuper
                  OR rolcreatedb
                  OR rolcreaterole
                  OR rolreplication
                  OR rolbypassrls
              )
        ) THEN
            RAISE EXCEPTION
                'Роль % имеет атрибуты, несовместимые с базовым стендом',
                role_name;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM pg_auth_members m
            JOIN pg_roles r
              ON r.oid = m.member
            WHERE r.rolname = role_name
        ) THEN
            RAISE EXCEPTION
                'Роль % состоит в другой роли',
                role_name;
        END IF;
    END LOOP;

    SELECT pg_get_userbyid(datdba)
    INTO actual_owner
    FROM pg_database
    WHERE datname = current_database();

    IF actual_owner <> 'ddc_owner' THEN
        RAISE EXCEPTION
            'Владельцем базы % должен быть ddc_owner, текущий владелец: %',
            current_database(),
            actual_owner;
    END IF;

    FOREACH schema_name IN ARRAY ARRAY[
        'meta',
        'raw',
        'stg',
        'xref',
        'core',
        'ops',
        'etl',
        'api',
        'mart'
    ]
    LOOP
        SELECT pg_get_userbyid(nspowner)
        INTO actual_owner
        FROM pg_namespace
        WHERE nspname = schema_name;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Схема % отсутствует', schema_name;
        END IF;

        IF actual_owner <> 'ddc_owner' THEN
            RAISE EXCEPTION
                'Владельцем схемы % должен быть ddc_owner, текущий владелец: %',
                schema_name,
                actual_owner;
        END IF;
    END LOOP;

    schema_migration_oid := to_regclass('meta.schema_migration');

    IF schema_migration_oid IS NULL THEN
        RAISE EXCEPTION 'Таблица meta.schema_migration отсутствует';
    END IF;

    SELECT pg_get_userbyid(relowner)
    INTO actual_owner
    FROM pg_class
    WHERE oid = schema_migration_oid
      AND relkind = 'r';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'meta.schema_migration не является таблицей';
    END IF;

    IF actual_owner <> 'ddc_owner' THEN
        RAISE EXCEPTION
            'Владельцем meta.schema_migration должен быть ddc_owner, текущий владелец: %',
            actual_owner;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_attribute
        WHERE attrelid = schema_migration_oid
          AND attname = 'migration_id'
          AND atttypid = 'text'::regtype
          AND attnotnull
          AND attnum > 0
          AND NOT attisdropped
    ) THEN
        RAISE EXCEPTION
            'Колонка meta.schema_migration.migration_id не соответствует основе стенда';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_attribute a
        JOIN pg_attrdef d
          ON d.adrelid = a.attrelid
         AND d.adnum = a.attnum
        WHERE a.attrelid = schema_migration_oid
          AND a.attname = 'applied_at'
          AND a.atttypid = 'timestamptz'::regtype
          AND a.attnotnull
          AND a.attnum > 0
          AND NOT a.attisdropped
          AND pg_get_expr(d.adbin, d.adrelid) = 'clock_timestamp()'
    ) THEN
        RAISE EXCEPTION
            'Колонка meta.schema_migration.applied_at не соответствует основе стенда';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        WHERE c.conrelid = schema_migration_oid
          AND c.contype = 'p'
          AND c.conname = 'pk_schema_migration'
          AND cardinality(c.conkey) = 1
          AND c.conkey[1] = (
              SELECT a.attnum
              FROM pg_attribute a
              WHERE a.attrelid = schema_migration_oid
                AND a.attname = 'migration_id'
                AND a.attnum > 0
                AND NOT a.attisdropped
          )
    ) THEN
        RAISE EXCEPTION
            'PRIMARY KEY meta.schema_migration не соответствует основе стенда';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM meta.schema_migration
        WHERE migration_id = '0001_initial'
    ) THEN
        RAISE EXCEPTION 'Миграция 0001_initial не зарегистрирована';
    END IF;
END
$$;

SELECT 'Проверка основы стенда пройдена' AS check_result;
