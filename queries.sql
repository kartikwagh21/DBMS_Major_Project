-- ============================================================================
-- CASE STUDY 19: Tuition Class Batch and Fee Ledger
-- FILE: queries.sql | Reporting Queries with Expected Output
-- ============================================================================

-- ----------------------------------------------------------------------------
-- (1) How much fee is outstanding per batch?
-- Uses a subquery to aggregate instalment payments per enrolment prior to joining,
-- avoiding duplicate counting caused by multiple fee payments per enrolment.
-- ----------------------------------------------------------------------------
SELECT 
    b.batch_id,
    b.batch_code,
    s.subject_name,
    COUNT(e.enrolment_id) AS total_active_enrolments,
    COALESCE(SUM(e.agreed_fee), 0.00) AS total_agreed_fee,
    COALESCE(SUM(f.total_paid), 0.00) AS total_paid_fee,
    COALESCE(SUM(e.agreed_fee), 0.00) - COALESCE(SUM(f.total_paid), 0.00) AS outstanding_fee
FROM batches b
JOIN subjects s ON b.subject_id = s.subject_id
LEFT JOIN enrolments e ON b.batch_id = e.batch_id AND e.status = 'ACTIVE'
LEFT JOIN (
    SELECT enrolment_id, SUM(amount_paid) AS total_paid
    FROM fee_instalments
    GROUP BY enrolment_id
) f ON e.enrolment_id = f.enrolment_id
GROUP BY b.batch_id, b.batch_code, s.subject_name
ORDER BY b.batch_id;

/*
EXPECTED OUTPUT:
 batch_id |   batch_code  |             subject_name             | total_active_enrolments | total_agreed_fee | total_paid_fee | outstanding_fee 
----------+---------------+--------------------------------------+-------------------------+------------------+----------------+-----------------
        1 | BATCH-MATH-M1 | Advanced Mathematics                 |                       5 |         75000.00 |       20000.00 |        55000.00
        2 | BATCH-PHYS-E1 | Physics Mechanics & Electromagnetism |                       4 |         56000.00 |       19000.00 |        37000.00
        3 | BATCH-CHEM-M1 | Organic & Inorganic Chemistry        |                       2 |         24000.00 |       14000.00 |        10000.00
        4 | BATCH-BIOL-E1 | Human Anatomy & Genetics             |                       2 |         22000.00 |       12000.00 |        10000.00
        5 | BATCH-CS-M1   | Data Structures & Algorithms         |                       2 |         32000.00 |        8000.00 |        24000.00
        6 | BATCH-MATH-E1 | Advanced Mathematics                 |                       0 |             0.00 |           0.00 |            0.00
(6 rows)
*/


-- ----------------------------------------------------------------------------
-- (2) Which students are enrolled in more than two batches?
-- Filters active enrolments and uses HAVING to identify students in > 2 batches.
-- ----------------------------------------------------------------------------
SELECT 
    s.student_id,
    s.student_code,
    s.first_name || ' ' || s.last_name AS student_name,
    COUNT(e.enrolment_id) AS enrolled_batches_count
FROM students s
JOIN enrolments e ON s.student_id = e.student_id
WHERE e.status = 'ACTIVE'
GROUP BY s.student_id, s.student_code, s.first_name, s.last_name
HAVING COUNT(e.enrolment_id) > 2
ORDER BY s.student_id;

/*
EXPECTED OUTPUT:
 student_id | student_code |  student_name  | enrolled_batches_count 
------------+--------------+----------------+------------------------
          1 | STU-001      | Aarav Patel    |                      3
          3 | STU-003      | Rohan Gupta    |                      3
(2 rows)
*/


-- ----------------------------------------------------------------------------
-- (3) Which batches are at full capacity?
-- Compares active enrolments count against the batch max_capacity column.
-- ----------------------------------------------------------------------------
SELECT 
    b.batch_id,
    b.batch_code,
    b.max_capacity,
    COUNT(e.enrolment_id) AS current_active_enrolments
FROM batches b
LEFT JOIN enrolments e ON b.batch_id = e.batch_id AND e.status = 'ACTIVE'
GROUP BY b.batch_id, b.batch_code, b.max_capacity
HAVING COUNT(e.enrolment_id) >= b.max_capacity
ORDER BY b.batch_id;

/*
EXPECTED OUTPUT:
 batch_id |   batch_code  | max_capacity | current_active_enrolments 
----------+---------------+--------------+---------------------------
        1 | BATCH-MATH-M1 |            5 |                         5
        2 | BATCH-PHYS-E1 |            4 |                         4
(2 rows)
*/


-- ----------------------------------------------------------------------------
-- (4) How much was collected in instalments each month?
-- Groups payment amounts by payment date formatted as YYYY-MM.
-- ----------------------------------------------------------------------------
SELECT 
    TO_CHAR(payment_date, 'YYYY-MM') AS collection_month,
    SUM(amount_paid) AS total_collected
FROM fee_instalments
GROUP BY TO_CHAR(payment_date, 'YYYY-MM')
ORDER BY collection_month;

/*
EXPECTED OUTPUT:
 collection_month | total_collected 
------------------+-----------------
 2026-02          |        33000.00
 2026-03          |        40000.00
(2 rows)
*/


-- ----------------------------------------------------------------------------
-- (5) Can two counters enrol students into the last seat of a batch at the
--     same time without overbooking?
-- Solution: Atomic Enrolment Transaction using Row-Level Locking (FOR UPDATE)
-- ----------------------------------------------------------------------------
BEGIN;

DO $$
DECLARE
    v_max_cap INT;
    v_curr_enrolled INT;
    v_batch_id INT := 3;     -- Target batch ID
    v_student_id INT := 10;  -- Enrolling student ID
    v_agreed_fee NUMERIC := 12000.00;
BEGIN
    -- Lock target batch row and fetch max_capacity atomically
    SELECT max_capacity INTO v_max_cap 
    FROM batches 
    WHERE batch_id = v_batch_id AND status = 'ACTIVE'
    FOR UPDATE;

    -- Count current active enrolments while holding the row lock
    SELECT COUNT(*) INTO v_curr_enrolled 
    FROM enrolments 
    WHERE batch_id = v_batch_id AND status = 'ACTIVE';

    IF v_curr_enrolled < v_max_cap THEN
        INSERT INTO enrolments (student_id, batch_id, agreed_fee, status)
        VALUES (v_student_id, v_batch_id, v_agreed_fee, 'ACTIVE');
        RAISE NOTICE 'Enrolment completed successfully (Seat % of % assigned).', v_curr_enrolled + 1, v_max_cap;
    ELSE
        RAISE NOTICE 'Enrolment rejected: Batch % has reached max capacity of % (Current active: %).', v_batch_id, v_max_cap, v_curr_enrolled;
    END IF;
END $$;

COMMIT;
/*
EXPECTED OUTPUT (When seat is available - 1st run):
NOTICE:  Enrolment completed successfully (Seat 3 of 3 assigned).
DO
COMMIT

EXPECTED OUTPUT (When capacity is full - 2nd run or already full):
NOTICE:  Enrolment rejected: Batch 3 has reached max capacity of 3 (Current active: 3).
DO
COMMIT
*/