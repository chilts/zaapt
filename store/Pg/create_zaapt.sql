-- ----------------------------------------------------------------------------

-- infrastructure
CREATE TABLE base (
    inserted        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE FUNCTION updated() RETURNS trigger as '
   BEGIN
      NEW.updated := CURRENT_TIMESTAMP;
      RETURN NEW;
   END;
' LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
