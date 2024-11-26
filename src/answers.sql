-- Your answers here:
-- 1
SELECT c.name,
    COUNT(c.name)
FROM countries c
    INNER JOIN states s ON c.id = s.country_id
GROUP BY c.name;
--2
SELECT COUNT(*) employees_without_bosses
FROM employees
WHERE supervisor_id IS NULL;
-- 3
SELECT c.name,
    o.address,
    COUNT(e.id) as count
FROM employees e
    INNER JOIN offices o ON e.office_id = o.id
    INNER JOIN countries c ON c.id = o.country_id
GROUP BY c.name,
    o.address
ORDER BY count DESC,
    c.name
LIMIT 5;
-- 4
SELECT supervisor_id,
    COUNT(supervisor_id) as count
FROM employees
GROUP BY supervisor_id
ORDER BY count DESC
LIMIT 3;
-- 5
SELECT COUNT(*) list_of_office
FROM offices o
    INNER JOIN states s ON o.state_id = s.id
WHERE s.name = 'Colorado';
-- 6
SELECT o.name,
    COUNT(o.name) as count
FROM offices o
    INNER JOIN employees e ON e.office_id = o.id
GROUP BY o.name
ORDER BY count DESC;
-- 7
WITH counts AS (
    SELECT COUNT(o.id) AS count
    FROM offices o
        INNER JOIN employees e ON e.office_id = o.id
    GROUP BY o.id
) (
    SELECT o.address,
        COUNT(o.id) as count
    FROM offices o
        INNER JOIN employees e ON e.office_id = o.id
    GROUP BY o.id
    HAVING COUNT(o.id) = (
            SELECT MAX(count)
            FROM counts
        )
    LIMIT 1
)
UNION ALL
(
    SELECT o.address,
        COUNT(o.id) as count
    FROM offices o
        INNER JOIN employees e ON e.office_id = o.id
    GROUP BY o.id
    HAVING COUNT(o.id) = (
            SELECT MIN(count)
            FROM counts
        )
    LIMIT 1
);
--8
SELECT e.uuid,
    e.first_name || ' ' || e.last_name as full_name,
    e.email,
    e.job_title,
    o.name company,
    c.name country,
    s.name state,
    es.first_name as boss_name
FROM employees e
    INNER JOIN offices o ON e.office_id = o.id
    INNER JOIN countries c ON c.id = o.country_id
    INNER JOIN employees es ON e.supervisor_id = es.id
    INNER JOIN states s ON s.id = o.state_id