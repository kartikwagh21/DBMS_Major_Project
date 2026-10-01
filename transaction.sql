-- ============================================================================
-- CASE STUDY 19: Tuition Class Batch and Fee Ledger
-- FILE: transaction.sql | Multi-step transaction with SAVEPOINT
-- Clean up any prior demo run so the file is 100% repeatable:
DELETE FROM enrolments WHERE student_id = 10 AND batch_id = 4;

BEGIN;

-- Step 1: Register Student 10 into Batch 4.
INSERT INTO enrolments
(student_id,batch_id,enrolment_date,agreed_fee,status)
VALUES (10,4,CURRENT_DATE,11000.00,'ACTIVE');

-- Savepoint after the successful enrolment.
SAVEPOINT enrolment_created;

-- Step 2: Deliberately invalid payment. amount_paid must be > 0.
INSERT INTO fee_instalments
(enrolment_id,instalment_number,amount_paid,payment_date,payment_mode,receipt_no)
VALUES (
    (SELECT enrolment_id
     FROM enrolments
     WHERE student_id=10 AND batch_id=4),
    1,0.00,CURRENT_DATE,'UPI','REC-2026-ERR'
);

-- Step 3: Recover only to the savepoint.
ROLLBACK TO SAVEPOINT enrolment_created;

-- Step 4: Retry with a valid payment.
INSERT INTO fee_instalments
(enrolment_id,instalment_number,amount_paid,payment_date,payment_mode,receipt_no)
VALUES (
    (SELECT enrolment_id
     FROM enrolments
     WHERE student_id=10 AND batch_id=4),
    1,5000.00,CURRENT_DATE,'UPI','REC-2026-013'
);

-- Step 5: Commit the complete operation.
COMMIT;


-- Verification:
SELECT e.enrolment_id,e.student_id,e.batch_id,e.agreed_fee,
       fi.amount_paid,fi.receipt_no
FROM enrolments e
JOIN fee_instalments fi ON fi.enrolment_id=e.enrolment_id
WHERE e.student_id=10 AND e.batch_id=4;

/*
EXPECTED VERIFICATION OUTPUT:
 enrolment_id | student_id | batch_id | agreed_fee | amount_paid |  receipt_no  
--------------+------------+----------+------------+-------------+--------------
           16 |         10 |        4 |   11000.00 |     5000.00 | REC-2026-013
(1 row)
*/