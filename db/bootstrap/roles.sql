DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddc_owner') THEN
        CREATE ROLE ddc_owner NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddc_loader') THEN
        CREATE ROLE ddc_loader NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddc_worker') THEN
        CREATE ROLE ddc_worker NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddc_analyst') THEN
        CREATE ROLE ddc_analyst NOLOGIN;
    END IF;
END
$$;
