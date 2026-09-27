CREATE OR REPLACE VIEW employees.dept_emp_latest_date AS
SELECT
    emp_no,
    MAX(from_date) AS from_date,
    MAX(to_date) AS to_date
FROM employees.dept_emp
GROUP BY emp_no;


CREATE OR REPLACE VIEW employees.current_dept_emp AS
SELECT
    l.emp_no,
    d.dept_no,
    l.from_date,
    l.to_date
FROM employees.dept_emp AS d
JOIN employees.dept_emp_latest_date AS l
    ON d.emp_no = l.emp_no
   AND d.from_date = l.from_date
   AND d.to_date = l.to_date;
