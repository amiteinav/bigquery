# BigQuery Scripting and Stored Procedures

## About
### Scripting 
Allows data engineers and data analysts to execute a wide range of tasks, from running queries in a sequence to multi-step tasks with control flow including IF statements and WHILE loops. 
It can also help with tasks that make use of variables. 

### Stored procedures 
Allows saving scripts and run them within BigQuery in the future. Similar to views, can be shared with others, all while maintaining one canonical version of the procedure.

## Demonstration 1

Combine queries and control logic to easily get query results. 
The result identifies the reporting hierarchy of an employee.

* Create a table running this against BigQuery 
```
CREATE TABLE `amiteinav-sandbox.Demos.Employees` AS
SELECT 1 AS employee_id, NULL AS manager_id UNION ALL  -- CEO
SELECT 2, 1 UNION ALL  -- VP
SELECT 3, 2 UNION ALL  -- Manager
SELECT 4, 2 UNION ALL  -- Manager
SELECT 5, 3 UNION ALL  -- Engineer
SELECT 6, 3 UNION ALL  -- Engineer
SELECT 7, 3 UNION ALL  -- Engineer
SELECT 8, 3 UNION ALL  -- Engineer
SELECT 9, 4 UNION ALL  -- Engineer
SELECT 10, 4 UNION ALL  -- Engineer
SELECT 11, 4 UNION ALL  -- Engineer
SELECT 12, 7  -- Intern;
```
* Create a stored procedure that returns the hierarchy for a given employee ID
```
-- The input variable is employee’s employee_id (target_employee_id)
  -- The output variable (OUT) is employee_hierarchy which lists
  --      the employee_id of the employee’s manager
CREATE PROCEDURE `amiteinav-sandbox.Demos`.GetEmployeeHierarchy(
  target_employee_id INT64, OUT employee_hierarchy ARRAY<INT64>)
BEGIN
  -- Iteratively search for this employee's manager, then the manager's
  -- manager, etc. until reaching the CEO, who has no manager.
  DECLARE current_employee_id INT64 DEFAULT target_employee_id;
  SET employee_hierarchy = [];
  WHILE current_employee_id IS NOT NULL DO
    -- Add the current ID to the array.
    SET employee_hierarchy =
      ARRAY_CONCAT(employee_hierarchy, [current_employee_id]);
    -- Get the next employee ID by querying the Employees table.
    SET current_employee_id = (
      SELECT manager_id FROM `amiteinav-sandbox.Demos.Employees`
      WHERE employee_id = current_employee_id
    );
  END WHILE;
END;
```

```
-- Change 9 to any other ID to see the hierarchy for that employee.
DECLARE target_employee_id INT64 DEFAULT 9;
DECLARE employee_hierarchy ARRAY<INT64>;

-- Call the stored procedure to get the hierarchy for this employee ID.
CALL `amiteinav-sandbox.Demos`.GetEmployeeHierarchy(target_employee_id, employee_hierarchy);

-- Show the hierarchy for the employee.
SELECT target_employee_id, employee_hierarchy;
```

## Demonstration 2

* Using temporary tables. Find a correlation between precipitation and number of births or birth weight in 1988 with the natality public data using temporary tables. 
It initially looks like there is no correlation
```
-- Day-level natality data is not available after 1988, and
-- state-level data is not available after 2004.
DECLARE target_year INT64 DEFAULT 1988;

CREATE TEMP TABLE SampledNatality AS
SELECT DATE(year, month, day) AS date, state, AVG(weight_pounds) AS avg_weight, COUNT(*) AS num_births
FROM `bigquery-public-data.samples.natality`
WHERE year = target_year
  AND SAFE.DATE(year, month, day) IS NOT NULL  -- Skip invalid dates
GROUP BY date, state;

IF (SELECT COUNT(*) FROM SampledNatality) = 0 THEN
  SELECT FORMAT("The year %d doesn't have day-level data", target_year);
  RETURN;
END IF;

CREATE TEMP TABLE StationsAndStates AS
SELECT wban, MAX(state) AS state
FROM `bigquery-public-data.noaa_gsod.stations`
GROUP BY wban;

CREATE TEMP TABLE PrecipitationByDateAndState AS
SELECT
  DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS date,
  (SELECT state FROM StationsAndStates AS stations
   WHERE stations.wban = gsod.wban) AS state,
  -- 99.99 indicates that precipitation was unknown
  AVG(NULLIF(prcp, 99.99)) AS avg_prcp
FROM `bigquery-public-data.noaa_gsod.gsod*` AS gsod
WHERE _TABLE_SUFFIX = CAST(target_year AS STRING)
GROUP BY date, state;

SELECT
  CORR(avg_weight, avg_prcp) AS weight_correlation,
  CORR(num_births, avg_prcp) AS num_births_correlation
FROM SampledNatality AS avg_weights
JOIN PrecipitationByDateAndState AS precipitation
USING (date, state);
```