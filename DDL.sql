BEGIN;

DROP TABLE IF EXISTS public.appointments;

CREATE TABLE IF NOT EXISTS public.appointments
(
    id integer NOT NULL DEFAULT nextval('appointments_id_seq'::regclass),
    patient_id integer NOT NULL,
    doctor_id integer NOT NULL,
    date date NOT NULL,
    "time" time without time zone NOT NULL,
    CONSTRAINT appointments_pkey PRIMARY KEY (id)
);

DROP TABLE IF EXISTS public.diagnoses;

CREATE TABLE IF NOT EXISTS public.diagnoses
(
    id integer NOT NULL DEFAULT nextval('diagnoses_id_seq'::regclass),
    patient_id integer NOT NULL,
    doctor_id integer NOT NULL,
    date date NOT NULL,
    diagnosis character varying(200) COLLATE pg_catalog."default",
    CONSTRAINT diagnoses_pkey PRIMARY KEY (id)
);

DROP TABLE IF EXISTS public.doctors;

CREATE TABLE IF NOT EXISTS public.doctors
(
    id integer NOT NULL DEFAULT nextval('doctors_id_seq'::regclass),
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    specialty character varying(50) COLLATE pg_catalog."default",
    CONSTRAINT doctors_pkey PRIMARY KEY (id)
);

DROP TABLE IF EXISTS public.patients;

CREATE TABLE IF NOT EXISTS public.patients
(
    id integer NOT NULL DEFAULT nextval('patients_id_seq'::regclass),
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    age integer,
    gender character(1) COLLATE pg_catalog."default",
    address character varying(100) COLLATE pg_catalog."default",
    phone character varying(20) COLLATE pg_catalog."default",
    CONSTRAINT patients_pkey PRIMARY KEY (id)
);

DROP TABLE IF EXISTS public.treatments;

CREATE TABLE IF NOT EXISTS public.treatments
(
    id integer NOT NULL DEFAULT nextval('treatments_id_seq'::regclass),
    diagnosis_id integer NOT NULL,
    medication character varying(50) COLLATE pg_catalog."default" NOT NULL,
    dosage character varying(50) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT treatments_pkey PRIMARY KEY (id)
);

ALTER TABLE IF EXISTS public.appointments
    ADD CONSTRAINT appointments_doctor_id_fkey FOREIGN KEY (doctor_id)
    REFERENCES public.doctors (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS public.appointments
    ADD CONSTRAINT appointments_patient_id_fkey FOREIGN KEY (patient_id)
    REFERENCES public.patients (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS public.diagnoses
    ADD CONSTRAINT diagnoses_doctor_id_fkey FOREIGN KEY (doctor_id)
    REFERENCES public.doctors (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS public.diagnoses
    ADD CONSTRAINT diagnoses_patient_id_fkey FOREIGN KEY (patient_id)
    REFERENCES public.patients (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS public.treatments
    ADD CONSTRAINT treatments_diagnosis_id_fkey FOREIGN KEY (diagnosis_id)
    REFERENCES public.diagnoses (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

END;

-- Functions
CREATE FUNCTION pacient_diagnoses(diagnosis_input varchar)
	RETURNS INT
	LANGUAGE plpgsql
AS
$$
DECLARE
	number_of_patients INT;
BEGIN
	SELECT COUNT(*)
	INTO number_of_patients
	FROM diagnoses
	WHERE diagnosis = diagnosis_input;
	
	RETURN number_of_patients;
END;
$$;

CREATE FUNCTION get_treatment_by_doc_pat(doctor_id int, patient_id int)
RETURNS TABLE (
	doctor_name VARCHAR(50),
	patient_name VARCHAR(50),
            treatment_id INT,
            diagnosis_id INT,
            medication VARCHAR(50),
            dosage VARCHAR(50)
 LANGUAGE plpgsql;
) AS $$
BEGIN
    RETURN QUERY
    SELECT doc.name AS doctor_name, p.name AS patient_name, t.id AS treatment_id, t.diagnosis_id, t.medication, t.dosage
    FROM treatments t
    JOIN diagnoses d ON t.diagnosis_id = d.id
    JOIN doctors doc ON doc.id = d.doctor_id
    JOIN patients p ON p.id = d.patient_id
    WHERE doc.id = doctor_id AND p.id = patient_id;
END;
$$


-- Procedures
CREATE PROCEDURE update_patient_info(patient_id_input INT, new_address VARCHAR(100), new_phone VARCHAR(20))
LANGUAGE plpgsql
AS $$
DECLARE
	patient RECORD;
BEGIN
	-- Fetch the patient row into the patient variable
	SELECT * INTO patient FROM patients WHERE id = patient_id_input;

	-- Update the patient's address and phone number if they have changed
	IF patient.address <> new_address OR patient.phone <> new_phone THEN
		UPDATE patients SET address = new_address, phone = new_phone WHERE id = patient_id_input;
		RAISE INFO 'Patient ID % information updated', patient_id_input;
	ELSE
		RAISE INFO 'No changes made to patient ID % information', patient_id_input;
	END IF;
END; $$;
