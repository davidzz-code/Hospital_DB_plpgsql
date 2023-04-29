INSERT INTO
    public.patients (name, age, gender, address, phone)
VALUES
    ('John Smith', 42, 'M', '123 Main St', '555-1234'),
    ('Jane Doe', 35, 'F', '456 Elm St', '555-5678'),
    ('Bob Johnson', 28, 'M', '789 Oak St', '555-9012'),
    ('Sara Lee', 45, 'F', '321 Pine St', '555-3456'),
    (
        'Tom Thompson',
        50,
        'M',
        '654 Maple St',
        '555-7890'
    );

INSERT INTO
    public.doctors (name, specialty)
VALUES
    ('Dr. Smith', 'Cardiology'),
    ('Dr. Johnson', 'Pediatrics'),
    ('Dr. Lee', 'Oncology'),
    ('Dr. Thompson', 'Dermatology'),
    ('Dr. Doe', 'Internal Medicine');

INSERT INTO
    diagnoses(patient_id, doctor_id, diagnosis, date)
VALUES
    (1, 1, 'flu', '2022-01-01'),
    (2, 2, 'cancer', '2022-02-01'),
    (3, 1, 'pneumonia', '2022-03-01'),
    (4, 3, 'flu', '2022-04-01'),
    (5, 2, 'cancer', '2022-05-01');

INSERT INTO
    treatments (diagnosis_id, medication, dosage)
VALUES
    (1, 'Ibuprofen', '400mg'),
    (2, 'Chemotherapy', '500mg'),
    (3, 'Antibiotics', '500mg'),
    (4, 'Tamiflu', '75mg'),
    (5, 'Radiation therapy', '2 Gy');

INSERT INTO appointments(patient_id, doctor_id, date, time)
VALUES (1, 2, '2023-05-01', '10:00:00');

INSERT INTO appointments(patient_id, doctor_id, date, time)
VALUES (3, 1, '2023-05-02', '15:30:00');

INSERT INTO appointments(patient_id, doctor_id, date, time)
VALUES (2, 5, '2023-05-03', '11:15:00');

INSERT INTO appointments(patient_id, doctor_id, date, time)
VALUES (4, 3, '2023-05-04', '16:45:00');

INSERT INTO appointments(patient_id, doctor_id, date, time)
VALUES (5, 4, '2023-05-05', '14:00:00');
