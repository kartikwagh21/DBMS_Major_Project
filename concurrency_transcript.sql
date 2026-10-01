-- ============================================================================
-- CASE STUDY 19: Tuition Class Batch and Fee Ledger
-- FILE: concurrency_transcript.sql
-- Two-session transcript: anomaly first, then the fix
-- ============================================================================

/*
PART A — TRUE LOST UPDATE

Use a clean seed. Batch 3 starts with max_capacity = 3.

SESSION 1                         SESSION 2
---------                         ---------
BEGIN;                            BEGIN;
SELECT max_capacity              SELECT max_capacity
FROM batches WHERE batch_id=3;   FROM batches WHERE batch_id=3;
-- 3                               -- 3

-- Application decides 4          -- Application decides 5
UPDATE batches SET max_capacity=4
WHERE batch_id=3;
COMMIT;

                                  UPDATE batches SET max_capacity=5
                                  WHERE batch_id=3;
                                  COMMIT;

FINAL VALUE = 5.
Session 1's change to 4 is lost because Session 2 updated from the stale
value it had previously read.

RESET:
UPDATE batches SET max_capacity=3 WHERE batch_id=3;
*/

/*
PART B — BUSINESS OVERBOOKING RACE

Seed state: Batch 3 has 2 active enrolments and capacity 3.

SESSION 1                         SESSION 2
---------                         ---------
BEGIN;                            BEGIN;

SELECT max_capacity,
       (SELECT COUNT(*)
        FROM enrolments
        WHERE batch_id=3
          AND status='ACTIVE')
FROM batches WHERE batch_id=3;
-- 3, 2                           -- 3, 2

INSERT INTO enrolments
(student_id,batch_id,agreed_fee,status)
VALUES (9,3,12000,'ACTIVE');
COMMIT;

                                  INSERT INTO enrolments
                                  (student_id,batch_id,agreed_fee,status)
                                  VALUES (10,3,12000,'ACTIVE');
                                  COMMIT;

RESULT: 4 active enrolments for capacity 3.

CLEANUP IF THIS UNSAFE DEMO WAS EXECUTED:
DELETE FROM enrolments
WHERE batch_id=3 AND student_id IN (9,10);
*/

/*
PART C — FIX USING ROW-LEVEL LOCKING + READ COMMITTED

SESSION 1                         SESSION 2
---------                         ---------
BEGIN;                            BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
                                  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT batch_id,max_capacity
FROM batches
WHERE batch_id=3
FOR UPDATE;
-- lock acquired                  SELECT batch_id,max_capacity
                                  FROM batches
                                  WHERE batch_id=3
                                  FOR UPDATE;
                                  -- BLOCKED / WAITING

SELECT COUNT(*)
FROM enrolments
WHERE batch_id=3 AND status='ACTIVE';
-- 2

INSERT INTO enrolments
(student_id,batch_id,enrolment_date,agreed_fee,status)
VALUES (9,3,CURRENT_DATE,12000,'ACTIVE');

COMMIT;
-- lock released

                                  -- Session 2 now continues
                                  SELECT COUNT(*)
                                  FROM enrolments
                                  WHERE batch_id=3 AND status='ACTIVE';
                                  -- 3

                                  -- No seat remains:
                                  ROLLBACK;

FINAL STATE: Batch 3 has 3 active enrolments for capacity 3.

WHY IT WORKS:
The batch row is locked before the capacity count. The second session cannot
perform its check until the first session commits. It then sees the fresh count
of 3 and does not insert another enrolment.

READ COMMITTED is sufficient here because the explicit FOR UPDATE lock
serializes the critical operation for the same batch.
*/

/* FINAL VERIFICATION */
SELECT b.batch_id,b.max_capacity,COUNT(e.enrolment_id) AS active_enrolments
FROM batches b
LEFT JOIN enrolments e
       ON e.batch_id=b.batch_id AND e.status='ACTIVE'
WHERE b.batch_id=3
GROUP BY b.batch_id,b.max_capacity;
-- Expected: 3 | 3 | 3
