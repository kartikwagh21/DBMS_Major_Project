-- ============================================================================
-- CASE STUDY 19: Tuition Class Batch and Fee Ledger
-- FILE: schema.sql | PostgreSQL DDL
-- ============================================================================

DROP TABLE IF EXISTS fee_instalments CASCADE;
DROP TABLE IF EXISTS enrolments CASCADE;
DROP TABLE IF EXISTS batches CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;
DROP TABLE IF EXISTS faculty CASCADE;

CREATE TABLE faculty (
    faculty_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL UNIQUE,
    specialization VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE subjects (
    subject_id SERIAL PRIMARY KEY,
    subject_code VARCHAR(15) NOT NULL UNIQUE,
    subject_name VARCHAR(100) NOT NULL,
    base_fee NUMERIC(10,2) NOT NULL CHECK (base_fee > 0)
);

CREATE TABLE batches (
    batch_id SERIAL PRIMARY KEY,
    batch_code VARCHAR(20) NOT NULL UNIQUE,
    subject_id INT NOT NULL REFERENCES subjects(subject_id) ON DELETE RESTRICT,
    faculty_id INT NOT NULL REFERENCES faculty(faculty_id) ON DELETE RESTRICT,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    days_of_week VARCHAR(50) NOT NULL,
    max_capacity INT NOT NULL CHECK (max_capacity > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE','COMPLETED','CANCELLED')),
    CONSTRAINT chk_batch_timing CHECK (end_time > start_time)
);

CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    student_code VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL UNIQUE,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE enrolments (
    enrolment_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    batch_id INT NOT NULL REFERENCES batches(batch_id) ON DELETE RESTRICT,
    enrolment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    agreed_fee NUMERIC(10,2) NOT NULL CHECK (agreed_fee >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE','COMPLETED','DROPPED')),
    CONSTRAINT uk_student_batch UNIQUE (student_id, batch_id)
);

CREATE TABLE fee_instalments (
    instalment_id SERIAL PRIMARY KEY,
    enrolment_id INT NOT NULL REFERENCES enrolments(enrolment_id) ON DELETE CASCADE,
    instalment_number INT NOT NULL CHECK (instalment_number > 0),
    amount_paid NUMERIC(10,2) NOT NULL CHECK (amount_paid > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_mode VARCHAR(20) NOT NULL
        CHECK (payment_mode IN ('CASH','UPI','CARD','NET_BANKING','CHEQUE')),
    receipt_no VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT uk_enrolment_instalment UNIQUE (enrolment_id, instalment_number)
);

CREATE INDEX idx_enrolments_student_id ON enrolments(student_id);
CREATE INDEX idx_enrolments_batch_id ON enrolments(batch_id);
CREATE INDEX idx_fee_instalments_enrolment_id ON fee_instalments(enrolment_id);
CREATE INDEX idx_fee_instalments_payment_date ON fee_instalments(payment_date);
CREATE INDEX idx_batches_subject_id ON batches(subject_id);

-- Capacity is enforced by the concurrent registration transaction:
-- SELECT ... FOR UPDATE -> count active enrolments -> insert if a seat exists.
