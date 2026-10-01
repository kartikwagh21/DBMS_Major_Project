-- ============================================================================
-- CASE STUDY 19: Tuition Class Batch and Fee Ledger
-- FILE: seed.sql | Realistic PostgreSQL sample data
-- ============================================================================

INSERT INTO faculty (first_name,last_name,email,phone,specialization) VALUES
('Ramesh','Sharma','ramesh.sharma@tuition.com','9820011111','Mathematics'),
('Ananya','Deshmukh','ananya.d@tuition.com','9820022222','Physics'),
('Sanjay','Verma','sanjay.v@tuition.com','9820033333','Chemistry'),
('Priya','Nair','priya.nair@tuition.com','9820044444','Biology'),
('Vikram','Mehta','vikram.m@tuition.com','9820055555','Computer Science');

INSERT INTO subjects (subject_code,subject_name,base_fee) VALUES
('MATH101','Advanced Mathematics',15000.00),
('PHYS101','Physics Mechanics & Electromagnetism',14000.00),
('CHEM101','Organic & Inorganic Chemistry',12000.00),
('BIOL101','Human Anatomy & Genetics',11000.00),
('CS101','Data Structures & Algorithms',16000.00);

INSERT INTO batches
(batch_code,subject_id,faculty_id,start_time,end_time,days_of_week,max_capacity,status)
VALUES
('BATCH-MATH-M1',1,1,'08:00','10:00','Mon,Wed,Fri',5,'ACTIVE'),
('BATCH-PHYS-E1',2,2,'17:00','19:00','Tue,Thu,Sat',4,'ACTIVE'),
('BATCH-CHEM-M1',3,3,'10:00','12:00','Mon,Wed,Fri',3,'ACTIVE'),
('BATCH-BIOL-E1',4,4,'16:00','18:00','Tue,Thu,Sat',10,'ACTIVE'),
('BATCH-CS-M1',5,5,'07:00','09:00','Mon,Wed,Fri',6,'ACTIVE'),
('BATCH-MATH-E1',1,1,'18:00','20:00','Tue,Thu,Sat',8,'ACTIVE');

INSERT INTO students
(student_code,first_name,last_name,email,phone,registration_date)
VALUES
('STU-001','Aarav','Patel','aarav.patel@gmail.com','9900010001','2026-01-05'),
('STU-002','Diya','Joshi','diya.joshi@gmail.com','9900010002','2026-01-06'),
('STU-003','Rohan','Gupta','rohan.gupta@gmail.com','9900010003','2026-01-10'),
('STU-004','Isha','Iyer','isha.iyer@gmail.com','9900010004','2026-01-12'),
('STU-005','Karan','Singh','karan.singh@gmail.com','9900010005','2026-01-15'),
('STU-006','Neha','Kulkarni','neha.k@gmail.com','9900010006','2026-01-18'),
('STU-007','Aditya','Rao','aditya.rao@gmail.com','9900010007','2026-01-20'),
('STU-008','Sneha','Reddy','sneha.r@gmail.com','9900010008','2026-01-22'),
('STU-009','Varun','Shah','varun.shah@gmail.com','9900010009','2026-01-25'),
('STU-010','Pooja','Verma','pooja.v@gmail.com','9900010010','2026-01-28');

-- Exactly 15 enrolments.
-- Batch 3 intentionally starts at 2/3 for the concurrency demonstration.
INSERT INTO enrolments
(student_id,batch_id,enrolment_date,agreed_fee,status)
VALUES
(1,1,'2026-02-01',15000,'ACTIVE'),
(1,2,'2026-02-01',14000,'ACTIVE'),
(1,5,'2026-02-02',16000,'ACTIVE'),
(2,1,'2026-02-01',15000,'ACTIVE'),
(2,4,'2026-02-03',11000,'ACTIVE'),
(3,1,'2026-02-04',15000,'ACTIVE'),
(3,2,'2026-02-04',14000,'ACTIVE'),
(3,3,'2026-02-05',12000,'ACTIVE'),
(4,3,'2026-02-05',12000,'ACTIVE'),
(4,5,'2026-02-06',16000,'ACTIVE'),
(5,1,'2026-02-10',15000,'ACTIVE'),
(6,1,'2026-02-10',15000,'ACTIVE'),
(7,2,'2026-02-11',14000,'ACTIVE'),
(8,2,'2026-02-12',14000,'ACTIVE'),
(9,4,'2026-02-15',11000,'ACTIVE');

INSERT INTO fee_instalments
(enrolment_id,instalment_number,amount_paid,payment_date,payment_mode,receipt_no)
VALUES
(1,1,5000,'2026-02-01','UPI','REC-2026-001'),
(1,2,5000,'2026-02-15','CARD','REC-2026-002'),
(2,1,7000,'2026-02-01','NET_BANKING','REC-2026-003'),
(4,1,5000,'2026-02-02','UPI','REC-2026-004'),
(5,1,6000,'2026-02-03','CASH','REC-2026-005'),
(7,1,5000,'2026-02-04','UPI','REC-2026-006'),
(1,3,5000,'2026-03-01','UPI','REC-2026-007'),
(2,2,7000,'2026-03-02','CARD','REC-2026-008'),
(3,1,8000,'2026-03-05','NET_BANKING','REC-2026-009'),
(5,2,6000,'2026-03-10','CASH','REC-2026-010'),
(8,1,6000,'2026-03-12','UPI','REC-2026-011'),
(9,1,8000,'2026-03-15','CARD','REC-2026-012');
