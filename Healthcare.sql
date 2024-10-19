-- create database
create database hospital;
-- create table demographics to load demographics csv file
use hospital;
CREATE TABLE demographics (
    encounter_id BIGINT,
    patient_nbr BIGINT,
    race VARCHAR(50),
    gender VARCHAR(20),
    age VARCHAR(20),
    weight VARCHAR(20),
    PRIMARY KEY (encounter_id)
);
-- create table health to load health csv file
use hospital;
CREATE TABLE health (
    encounter_id BIGINT,
    patient_nbr BIGINT,
    admission_type_id INT,
    discharge_disposition_id INT,
    admission_source_id INT,
    time_in_hospital INT,
    payer_code VARCHAR(20),
    medical_specialty VARCHAR(50),
    num_lab_procedures INT,
    num_procedures INT,
    num_medications INT,
    number_outpatient INT,
    number_emergency INT,
    number_inpatient INT,
    number_diagnoses INT,
    changes VARCHAR(10),
    diabetesMed VARCHAR(10),
    readmitted VARCHAR(10),
    PRIMARY KEY (encounter_id)
);
-- checking demographics and health table structure
select * from hospital.demographics;
select * from hospital.health;


-- Find the no. of patients for the different no. of days staying at hospital

SELECT 
    time_in_hospital AS days_at_hospital,
    COUNT(*) AS patient_count, 
    (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER () AS percent
FROM health
GROUP BY time_in_hospital
ORDER BY patient_count desc;
        
-- To find out correlation between num_lab_procedures and time_in_hospital

SELECT min(num_lab_procedures),
avg(num_lab_procedures),
max(num_lab_procedures)
FROM health;

SELECT 
    CASE 
        WHEN time_in_hospital <= 4 THEN '0-4 Days'  -- create time_in_hospital bucket
        WHEN time_in_hospital <= 8 THEN '5-8 Days'
        ELSE '9+ Days'
    END AS stay_duration,
    AVG(num_lab_procedures) AS avg_procedures, -- check avg no.of procedures done
    COUNT(*) AS patient_count,
    (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER () AS percent_patients -- check patients percentage for each bucket of days
FROM health
GROUP BY stay_duration
ORDER BY AVG(num_lab_procedures)desc;


-- Find if racial bias in number of lab procedures received

select distinct race, 
count(patient_nbr) as total_patients -- checking breakdown of population in each race
from hospital.demographics 
group by demographics.race;

select demographics.race, 
count(health.num_lab_procedures) as total_lab_procedures, 
avg(health.num_lab_procedures) as avg_lab_procedures
from hospital.demographics 
Join hospital.health
on demographics.patient_nbr = health.patient_nbr
group by demographics.race;

-- Which medical specialties perform the most lab procedures?
SELECT medical_specialty FROM health; -- Check the medical speciality column

SELECT DISTINCT medical_specialty, 
round(avg(num_lab_procedures),1) AS avg_lab_procedure, 
count(*) as Count
FROM health
GROUP BY medical_specialty
ORDER BY count(*) DESC;

SELECT 
    CASE 
        WHEN count(*) >=10000  THEN 'HIGH_TRAFFIC'  -- create visitors bucket
        WHEN count(*) >=3000  THEN 'MEDIUM_TRAFFIC'
        ELSE 'LOW_TRAFFIC'
    END AS TRAFFIC,
	COUNT(*) as Count_report,
    medical_specialty, 
    round(avg(num_lab_procedures),1) AS avg_lab_procedure
FROM health
GROUP BY medical_specialty
HAVING COUNT(*) >= 1000 
ORDER BY COUNT(*) DESC;

-- Patient readmission within 30 days or not
SELECT readmitted FROM health;
SELECT 
	CASE 
		WHEN readmitted = '>30' THEN 'AFTER 30 DAYS'
		WHEN readmitted = '<30' THEN 'BEFORE 30 DAYS'
        ELSE 'NOT ADMITTED'
	END AS readmission,
	count(patient_nbr) as visitors, 
    count(*) * 100/SUM(COUNT(*)) OVER () AS percent_visitors  
    FROM health
    GROUP BY readmitted
    ORDER BY count(patient_nbr) Desc;

-- checking readmission less than 30 days with respect to race    

SELECT 
    CASE 
        WHEN health.readmitted = '>30' THEN 'AFTER 30 DAYS'
        WHEN health.readmitted = '<30' THEN 'BEFORE 30 DAYS'
        ELSE 'NOT ADMITTED'
    END AS readmission,
    COUNT(health.patient_nbr) AS visitors, 
    (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER () AS percent_visitors, 
    demographics.race 
FROM 
    demographics 
JOIN 
    health 
ON 
    demographics.patient_nbr = health.patient_nbr
GROUP BY 
    health.readmitted, demographics.race
HAVING readmitted = "<30"
ORDER BY 
    visitors DESC;
    
-- Patients receiving the most medication and lab procedures
SELECT 
    h.patient_nbr, 
    d.race, 
    h.num_medications, 
    h.num_lab_procedures,
    (h.num_medications + h.num_lab_procedures) AS total_procedures
FROM 
    health h
JOIN 
    demographics d 
ON 
    h.patient_nbr = d.patient_nbr
ORDER BY 
    total_procedures DESC
LIMIT 10;

-- Write a summary for these patients with their total medications and procedures.

SELECT 
    h.patient_nbr, 
    d.race, 
    h.num_medications, 
    h.num_lab_procedures,
    (h.num_medications + h.num_lab_procedures) AS total_procedures,
    CASE 
        WHEN h.readmitted = '>30' THEN 'AFTER 30 DAYS'
        WHEN h.readmitted = '<30' THEN 'BEFORE 30 DAYS'
        ELSE 'NOT ADMITTED'
    END AS readmission_status,
    CONCAT('Patient no. ', h.patient_nbr, ' was ', d.race, ' has received ', h.num_medications, 
    ' medications and ', h.num_lab_procedures, ' lab procedures and was ', 
           CASE 
               WHEN h.readmitted = '>30' THEN 'readmitted after 30 days'
               WHEN h.readmitted = '<30' THEN 'readmitted before 30 days'
               ELSE 'not readmitted'
           END
    ) AS summary
FROM health h
JOIN demographics d 
ON h.patient_nbr = d.patient_nbr
ORDER BY total_procedures DESC
LIMIT 10;

-- speciality with max no.of procedures

SELECT medical_specialty, 
COUNT(num_procedures) AS total_procedure,
ROUND(COUNT(num_procedures)* 100/SUM(COUNT(num_procedures)) OVER (),1) AS percent_procedures
FROM health
GROUP BY medical_specialty
ORDER BY COUNT(num_procedures) DESC;

-- Total no of specialties
SELECT count(DISTINCT medical_specialty)
FROM health;

-- How many patients received care under each specialty, and which medical specialties have a count of more than 50 patients

SELECT medical_specialty, 
COUNT(patient_nbr) AS patient_count
FROM health
GROUP BY medical_specialty
HAVING COUNT(patient_nbr) > 50
ORDER BY COUNT(patient_nbr) DESC;

-- Which medical specialty has more than 2.5 average procedures

SELECT medical_specialty, 
round(AVG(num_procedures),1) AS AVG_procedure
FROM health
GROUP BY medical_specialty
HAVING AVG(num_procedures) > 2.5
ORDER BY AVG(num_procedures) DESC;

-- patients that came into the hospital with an emergency (admission_type_id of 1) and stayed for less than the average time
SELECT AVG(time_in_hospital) FROM HEALTH; -- avg hospital time

SELECT patient_nbr, admission_type_id, AVG(time_in_hospital) AS Avg_time
FROM HEALTH
WHERE admission_type_id = 1
GROUP BY patient_nbr, admission_type_id
HAVING AVG(time_in_hospital) < (SELECT AVG(time_in_hospital) FROM HEALTH)
ORDER BY Avg_time DESC;






