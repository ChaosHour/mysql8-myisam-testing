CREATE DATABASE IF NOT EXISTS testdb;

USE testdb;

CREATE TABLE IF NOT EXISTS employees (
     id INT AUTO_INCREMENT PRIMARY KEY,
     first_name VARCHAR(50),
     last_name VARCHAR(50),
     email VARCHAR(100),
     hire_date DATE,
     salary DECIMAL(10, 2),
     INDEX(last_name)
 ) ENGINE=MyISAM;

-- Drop the procedure if it already exists
DROP PROCEDURE IF EXISTS insert_employees;

DELIMITER $$
CREATE PROCEDURE insert_employees()
BEGIN
     DECLARE i INT DEFAULT 1;
     WHILE i <= 1000 DO
         INSERT INTO employees (first_name, last_name, email, hire_date,
salary)
         VALUES (
             CONCAT('FirstName', i),
             CONCAT('LastName', i),
             CONCAT('employee', i, '@example.com'),
             DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND()*1095) DAY),
             ROUND(30000+RAND()*70000, 2)
         );
         SET i = i + 1;
     END WHILE;
END$$
DELIMITER ;

CALL insert_employees();
DROP PROCEDURE insert_employees;
