DO $$
DECLARE
    role_name text;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddc_owner') THEN
        CREATE ROLE ddc_owner
            NOLOGIN
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            NOREPLICATION
            NOBYPASSRLS;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddc_loader') THEN
        CREATE ROLE ddc_loader
            NOLOGIN
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            NOREPLICATION
            NOBYPASSRLS;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddc_worker') THEN
        CREATE ROLE ddc_worker
            NOLOGIN
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            NOREPLICATION
            NOBYPASSRLS;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddc_analyst') THEN
        CREATE ROLE ddc_analyst
            NOLOGIN
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            NOREPLICATION
            NOBYPASSRLS;
    END IF;

    FOREACH role_name IN ARRAY ARRAY[
        'ddc_owner',
        'ddc_loader',
        'ddc_worker',
        'ddc_analyst'
    ]
    LOOP
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
END
$$;
