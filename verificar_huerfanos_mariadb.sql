SELECT 'dept_emp -> employees' AS relacion, COUNT(*) AS huerfanos
FROM dept_emp d
LEFT JOIN employees e ON d.emp_no = e.emp_no
WHERE e.emp_no IS NULL

UNION ALL

SELECT 'dept_emp -> departments', COUNT(*)
FROM dept_emp d
LEFT JOIN departments p ON d.dept_no = p.dept_no
WHERE p.dept_no IS NULL

UNION ALL

SELECT 'dept_manager -> employees', COUNT(*)
FROM dept_manager d
LEFT JOIN employees e ON d.emp_no = e.emp_no
WHERE e.emp_no IS NULL

UNION ALL

SELECT 'dept_manager -> departments', COUNT(*)
FROM dept_manager d
LEFT JOIN departments p ON d.dept_no = p.dept_no
WHERE p.dept_no IS NULL

UNION ALL

SELECT 'salaries -> employees', COUNT(*)
FROM salaries s
LEFT JOIN employees e ON s.emp_no = e.emp_no
WHERE e.emp_no IS NULL

UNION ALL

SELECT 'titles -> employees', COUNT(*)
FROM titles t
LEFT JOIN employees e ON t.emp_no = e.emp_no
WHERE e.emp_no IS NULL;
