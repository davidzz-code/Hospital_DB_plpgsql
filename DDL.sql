-- ### SEQUENCIES ###
CREATE SEQUENCE public.appointments_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.diagnoses_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.doctors_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.patients_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.treatments_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;


-- ### TABLES ###
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


-- ### FUNCTIONS ###
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
)
LANGUAGE plpgsql AS $$
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


-- ### PROCEDURES ###
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



CREATE OR REPLACE PROCEDURE view_medical_history(patient_id_input INT)
LANGUAGE plpgsql 
AS $$
DECLARE
    medical_history record;
BEGIN
    RAISE NOTICE 'Initiating procedure for patient with ID: %', patient_id_input;
    
    SELECT patients.id, patients.name, diagnosis, medication, dosage
    INTO medical_history
    FROM patients
    JOIN diagnoses ON diagnoses.patient_id = patients.id
    JOIN treatments ON treatments.diagnosis_id = diagnoses.id
    WHERE patients.id = patient_id_input;
    
    RAISE NOTICE 'Record found';
    RAISE NOTICE 'Patient ID: %, Name: %, Diagnosis: %, Medication: %, Dosage: %', 
    medical_history.id, medical_history.name, medical_history.diagnosis, medical_history.medication, medical_history.dosage;
END;
$$


-- ### CURSORS ###
-- Returns the available doctors on the specified date
CREATE OR REPLACE FUNCTION get_available_doctors(date_input date, time_input time)
RETURNS TABLE(doctor_id INTEGER, doctor_name VARCHAR(50)) AS $$
DECLARE
    available_doctors CURSOR FOR
        SELECT doctors.id AS doctor_id, doctors.name AS doctor_name
        FROM Doctors
        LEFT OUTER JOIN appointments AS app ON app.doctor_id = doctors.id AND app.date = date_input AND app.time = time_input
        WHERE app.id is NULL;
    
BEGIN
    OPEN available_doctors;
    RETURN QUERY FETCH ALL FROM available_doctors;
    CLOSE available_doctors;
END;
$$
LANGUAGE plpgsql;



-- Returns patient's name and age
CREATE OR REPLACE FUNCTION get_patients_info()
RETURNS text AS
$$
DECLARE
    patient_info text default '';
    rec_patients_info record;
    patients_name_age CURSOR FOR
        SELECT name, age
        FROM patients;
BEGIN
    OPEN patients_name_age;
    LOOP
        FETCH patients_name_age INTO rec_patients_info;
        EXIT WHEN NOT FOUND;    

        patient_info := patient_info || ' | ' || rec_patients_info.name || ' is: ' || rec_patients_info.age || ' years old';
    END LOOP;
    CLOSE patients_name_age;
    
    RETURN patient_info;
END;
$$
LANGUAGE plpgsql;



-- Returns doctor's name and specialty
CREATE OR REPLACE FUNCTION get_doctors_info()
RETURNS TABLE(doctor_name VARCHAR(50), doctor_specialty VARCHAR(50)) AS 
$$
DECLARE
    doctors_info CURSOR FOR
        SELECT name, specialty
        FROM doctors;
BEGIN
    OPEN doctors_info;
    LOOP
        FETCH doctors_info INTO doctor_name, doctor_specialty;
        EXIT WHEN NOT FOUND;    

        RETURN NEXT;
    END LOOP;
    CLOSE doctors_info;
END;
$$
LANGUAGE plpgsql;



-- ### TRIGGERS ###
-- Checks doctor's availability
CREATE OR REPLACE FUNCTION check_availability()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
DECLARE
    conflicting_appointments INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO conflicting_appointments
    FROM appointments
    WHERE doctor_id = NEW.doctor_id
        AND date = NEW.date
        AND time = NEW.time;

    IF conflicting_appointments > 0 THEN
        RAISE EXCEPTION 'Doctor is not available at this time.';
    END IF;

    RETURN NEW;
END;
$$

CREATE TRIGGER check_availability_trigger
    BEFORE INSERT
    ON appointments
    FOR EACH row
    EXECUTE PROCEDURE check_availability();
--


-- Inserts or updates a row in "diagnoses" table depending on "appointments" table
CREATE OR REPLACE FUNCTION update_diagnoses()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO diagnoses(patient_id, doctor_id, diagnosis, date)
        VALUES (NEW.patient_id, NEW.doctor_id, NULL, NEW.date);
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE diagnoses
        SET diagnosis = NULL
        WHERE doctor_id = NEW.doctor_id AND patient_id = NEW.patient_id;
    END IF;

    RETURN NEW;
END;
$$

CREATE TRIGGER update_diagnoses_trigger
    AFTER INSERT OR UPDATE ON appointments
    FOR EACH ROW
    EXECUTE FUNCTION update_diagnoses();
--