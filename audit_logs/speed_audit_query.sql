/*

Run the following query to get the number of bytes processed by each query and the estimated cost (in USD). The logs will show the amount of bytes processed, the estimated cost of the query, and some other information about your queries

*/

WITH
  logs AS (
  SELECT
    timestamp,
    protopayload_auditlog.servicedata_v1_bigquery.jobInsertResponse.resource.jobStatistics.totalProcessedBytes AS bytes_processed,
    protopayload_auditlog.servicedata_v1_bigquery.jobInsertRequest.resource.jobConfiguration.query.query AS query,
    p.projectId,
    p.datasetId,
    p.tableId,
    protopayload_auditlog.servicedata_v1_bigquery.jobInsertResponse.resource.jobStatus.state AS jobstate
  FROM
    `DATASET.cloudaudit_googleapis_com_data_access*`,
    UNNEST(protopayload_auditlog.servicedata_v1_bigquery.jobInsertResponse.resource.jobStatistics.referencedTables) AS p
  WHERE
    protopayload_auditlog.servicedata_v1_bigquery.jobInsertResponse.resource.jobStatus.state = 'DONE'
    AND protopayload_auditlog.servicedata_v1_bigquery.jobInsertResponse.resource.jobStatus.error.message IS NULL
    AND p.tableId NOT LIKE 'cloudaudit%')
SELECT
  timestamp,
  projectId,
  datasetId,
  tableId,
  bytes_processed,
  FORMAT('%9.2f', 5.0 * (bytes_processed/POWER(2, 40))) AS Estimated_USD_Cost,
  query,
  jobstate
FROM
  logs
ORDER BY
  timestamp DESC