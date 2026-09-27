SELECT 'dept_emp -> employees' AS relacion, COUNT(*) AS huerfanos
FROM employees.dept_emp d
LEFT JOIN employees.employees e ON d.emp_no = e.emp_no
WHERE e.emp_no IS NULL

UNION ALL

SELECT 'dept_emp -> departments', COUNT(*)
FROM employees.dept_emp d
LEFT JOIN employees.departments p ON d.dept_no = p.dept_no
WHERE p.dept_no IS NULL

UNION ALL

SELECT 'dept_manager -> employees', COUNT(*)
FROM employees.dept_manager d
LEFT JOIN employees.employees e ON d.emp_no = e.emp_no
WHERE e.emp_no IS NULL

UNION ALL

SELECT 'dept_manager -> departments', COUNT(*)
FROM employees.dept_manager d
LEFT JOIN employees.departments p ON d.dept_no = p.dept_no
WHERE p.dept_no IS NULL

UNION ALL

SELECT 'salaries -> employees', COUNT(*)
FROM employees.salaries s
LEFT JOIN employees.employees e ON s.emp_no = e.emp_no
WHERE e.emp_no IS NULL

UNION ALL

SELECT 'titles -> employees', COUNT(*)
FROM employees.titles t
LEFT JOIN employees.employees e ON t.emp_no = e.emp_no
WHERE e.emp_no IS NULL;
