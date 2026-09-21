DO $$
DECLARE
    role_name text;
    schema_name text;
    actual_owner text;
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
              AND rolcanlogin = false
        ) THEN
            RAISE EXCEPTION 'Роль % отсутствует или имеет атрибут LOGIN', role_name;
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

    IF to_regclass('meta.schema_migration') IS NULL THEN
        RAISE EXCEPTION 'Таблица meta.schema_migration отсутствует';
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
