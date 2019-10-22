# BigQuery Audit Logs

## Overview
* Cloud Audit Logs are a collection of logs provided by Google Cloud Platform that provide insight into operational concerns related to your use of Google Cloud services. Here are details about BigQuery specific log information

* Here you will find details on 
  * Setting audit logs stream into BigQuery
  * Querying the information wither by using queries or datastudio

## Reference
* https://cloud.google.com/bigquery/docs/reference/auditlogs/
* https://github.com/GoogleCloudPlatform/professional-services/tree/master/examples/bigquery-audit-log

## Setting it up

* Choose where to place the logs
```
export sink=bigquery_audit
export project=`gcloud config get-value project`
export auditlog_dataset=auditlog_dataset
export location=US
```
* You can check if the dataset exists 
```
bq ls -d ${project}: | grep -w ${auditlog_dataset}
```
* Create the dataset 
```
bq mk --location $location \
--dataset ${project}:${auditlog_dataset} 
```
* Create a sink for the entire BigQuery logging
```
gcloud logging sinks create $sink \
 bigquery.googleapis.com/projects/${project}/datasets/${auditlog_dataset} \
  --log-filter='resource.type="bigquery_resource"'
```
* This is how to create a sink for BigQueryAuditMetadata - not to be used at this point. It creates a smaller table. 
```
gcloud logging sinks create $sink \
 bigquery.googleapis.com/projects/${project}/datasets/${auditlog_dataset} \
  --log-filter='protoPayload.metadata."@type"="type.googleapis.com/google.cloud.audit.BigQueryAuditMetadata"'
```
* Get the service account for the sink
```
service_account=`gcloud logging sinks describe $sink --format="value(writerIdentity)"`
echo $service_account
```
* Get the current permissions to the dataset
```
bq show --format=prettyjson ${project}:${auditlog_dataset} > policy.yaml
```
* Add a row like this in the policy.yaml file and make sure to replace ${service_account} with the service account
```
    {
      "role": "WRITER", 
      "userByEmail": "${service_account}"
    },
```
* Apply the new policy file
```
bq update --source policy.yaml ${project}:${auditlog_dataset}
```
* From this point on there should be audit logs flowing. two tablbes 
  * cloudaudit_googleapis_com_activity_YYYYMMDD
  * cloudaudit_googleapis_com_data_access_YYYYMMDD

## Scheduling the query for the dashboard view


## Examples
* Query cost breakdown by identity
```
  WITH data as
  (
    SELECT
      protopayload_auditlog.authenticationInfo.principalEmail as principalEmail,
      protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent AS jobCompletedEvent
    FROM
      `MYPROJECTID.MYDATASETID.cloudaudit_googleapis_com_data_access_YYYYMMDD`
  )
  SELECT
    principalEmail,
    FORMAT('%9.2f',5.0 * (SUM(jobCompletedEvent.job.jobStatistics.totalBilledBytes)/POWER(2, 40))) AS Estimated_USD_Cost
  FROM
    data
  WHERE
    jobCompletedEvent.eventName = 'query_job_completed'
  GROUP BY principalEmail
  ORDER BY Estimated_USD_Cost DESC
  ```
* Hourly cost breakdown
```  
SELECT
    TIMESTAMP_TRUNC(protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.endTime, HOUR) AS time_window,
    FORMAT('%9.2f',5.0 * (SUM(protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalBilledBytes)/POWER(2, 40))) AS Estimated_USD_Cost
  FROM
    `MYPROJECTID.MYDATASETID.cloudaudit_googleapis_com_data_access_YYYYMMDD`
  WHERE
    protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.eventName = 'query_job_completed'
  GROUP BY time_window
      ORDER BY time_window DESC
```
* Most popular datasets
```
  #standardSQL
  SELECT
    REGEXP_EXTRACT(protopayload_auditlog.resourceName, '^projects/[^/]+/datasets/([^/]+)/tables') AS datasetRef,
    COUNT(DISTINCT REGEXP_EXTRACT(protopayload_auditlog.resourceName, '^projects/[^/]+/datasets/[^/]+/tables/(.*)$')) AS active_tables,
    COUNTIF(JSON_EXTRACT(protopayload_auditlog.metadataJson, "$.tableDataRead") IS NOT NULL) AS dataReadEvents,
    COUNTIF(JSON_EXTRACT(protopayload_auditlog.metadataJson, "$.tableDataChange") IS NOT NULL) AS dataChangeEvents
  FROM `MYPROJECTID.MYDATASETID.cloudaudit_googleapis_com_data_access_2019*`
  WHERE
    JSON_EXTRACT(protopayload_auditlog.metadataJson, "$.tableDataRead") IS NOT NULL
    OR JSON_EXTRACT(protopayload_auditlog.metadataJson, "$.tableDataChange") IS NOT NULL
  GROUP BY datasetRef
  ORDER BY datasetRef
```

* Get information by API status code
```
SELECT * FROM (
SELECT 
 a. resource.type as type,
 a. resource.labels.project_id as project_id,
 a. protopayload_auditlog.methodName as method_name,
a. protopayload_auditlog.numResponseItems as num_res_Items,
a. protopayload_auditlog.status.code as status_code,
a. protopayload_auditlog.status.message as status_message,
a. protopayload_auditlog.authenticationInfo.principalEmail as auth_email,
a. protopayload_auditlog.authenticationInfo.authoritySelector as auth_selector,
a. protopayload_auditlog.authenticationInfo.serviceAccountKeyName as auth_service_name, 
--a. protopayload_auditlog.authorizationInfo.resource as auth_resource,
--a. protopayload_auditlog.authorizationInfo.permission as auth_permission,
--a. protopayload_auditlog.authorizationInfo.granted as granted,
a. protopayload_auditlog.requestMetadata.callerIp as caller_ip,
a. protopayload_auditlog.requestMetadata.callerSuppliedUserAgent as user_agent,
a. protopayload_auditlog.requestMetadata.callerNetwork as caller_network,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsRequest.maxResults as max_results,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsRequest.startRow as start_row,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.totalResults as response_total_results,
--a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.projectId as response_project_id,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobName.jobId as response_job_id,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobConfiguration.query.queryPriority as query_priority,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobConfiguration.query.statementType as statement_type,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobConfiguration.dryRun as dry_run,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatus.state as job_state,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.createTime as create_time,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.startTime as start_time,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.endTime as end_time,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.totalProcessedBytes as total_proc_bytes,
a. protopayload_auditlog.servicedata_v1_bigquery.jobgetqueryresultsresponse.job.jobStatistics.totalBilledBytes as total_billed_bytes,
a. protopayload_auditlog.servicedata_v1_bigquery.jobgetqueryresultsresponse.job.jobStatistics.totalSlotMs as total_slot_ms,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.totalTablesProcessed as total_table_proc,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.totalLoadOutputBytes as output_bytes,
textpayload, timestamp, severity,
a. protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobConfiguration.query.query as query,
a. logName as  log_name, 
a. protopayload_auditlog.resourceName as resources_name
from 
  `bq_logs.cloudaudit_googleapis_com_data_access_20190201` a
  where  a. protopayload_auditlog.methodName = 'jobservice.getqueryresults'
  ) WHERE status_code = 8
```
* Get the number of bytes processed by each query and the estimated cost (in USD). The logs will show the amount of bytes processed, the estimated cost of the query, and some other information about the queries.
```
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
```
* A user friendly view for querying the audit logs
```
WITH query_audit AS (
SELECT
protopayload_auditlog.authenticationInfo.principalEmail,
protopayload_auditlog.requestMetadata.callerIp,
protopayload_auditlog.serviceName,
protopayload_auditlog.methodName,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.eventName,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobName.projectId,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobName.jobId,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.createTime,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.startTime,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.endTime,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatus.error.code as errorCode,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatus.error.message as errorMessage,
TIMESTAMP_DIFF(
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.endTime,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.startTime, MILLISECOND) as runtimeMs,
TIMESTAMP_DIFF(
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.endTime,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.startTime, MILLISECOND) / 1000 as runtimeSecs,
CAST(CEIL((TIMESTAMP_DIFF(
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.endTime,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.startTime, MILLISECOND) / 1000) / 60) AS INT64) as executionMinuteBuckets,
CASE
WHEN
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalProcessedBytes IS NULL
AND protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalSlotMs IS NULL
AND protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatus.error.code IS NULL
THEN true
ELSE false
END as cached,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalSlotMs,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalTablesProcessed,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalViewsProcessed,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalProcessedBytes,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalBilledBytes,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.billingTier,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobConfiguration.query,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.referencedTables,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.referencedViews
FROM
`tests.cloudaudit_googleapis_com_data_access_*`
WHERE
_table_suffix between '20181101' and '20181130'
)

-- Query the audit
SELECT
principalEmail,
callerIp,
serviceName,
methodName,
eventName,
projectId,
jobId,
CASE
WHEN REGEXP_CONTAINS(jobId, 'beam') THEN true
ELSE false
END as isBeamJob,
CASE
WHEN REGEXP_CONTAINS(query.query, 'cloudaudit_googleapis_com_data_access_') THEN true
ELSE false
END as isAuditDashboardQuery,
errorCode,
errorMessage,
CASE
WHEN errorCode IS NOT NULL THEN true
ELSE false
END as isError,
CASE
WHEN REGEXP_CONTAINS(errorMessage, 'timeout') THEN true
ELSE false
END as isTimeout,
STRUCT(
EXTRACT(MINUTE FROM createTime) as minuteOfDay,
EXTRACT(HOUR FROM createTime) as hourOfDay,
EXTRACT(DAYOFWEEK FROM createTime) - 1 as dayOfWeek,
EXTRACT(DAYOFYEAR FROM createTime) as dayOfYear,
EXTRACT(ISOWEEK FROM createTime) as week,
EXTRACT(MONTH FROM createTime) as month,
EXTRACT(QUARTER FROM createTime) as quarter,
EXTRACT(YEAR FROM createTime) as year
) as date,
createTime,
startTime,
endTime,
runtimeMs,
runtimeSecs,
cached,
totalSlotMs,
totalSlotMs / runtimeMs as avgSlots,

/* The following statement breaks down the query into minute buckets
* and provides the average slot usage within that minute. This is a
* crude way of making it so you can retrieve the average slot utilization
* for a particular minute across multiple queries.
*/
ARRAY(
SELECT
STRUCT(
TIMESTAMP_TRUNC(TIMESTAMP_ADD(startTime, INTERVAL bucket_num MINUTE), MINUTE) as time,
totalSlotMs / runtimeMs as avgSlotUsage
)
FROM
UNNEST(GENERATE_ARRAY(1, executionMinuteBuckets)) as bucket_num
) as executionTimeline,

totalTablesProcessed,
totalViewsProcessed,
totalProcessedBytes,
totalBilledBytes,
(totalBilledBytes / 1000000000) as totalBilledGigabytes,
(totalBilledBytes / 1000000000) / 1000 as totalBilledTerabytes,
((totalBilledBytes / 1000000000) / 1000) * 5 as estimatedCostUsd,
billingTier,
query,
referencedTables,
referencedViews,
1 as queries
FROM
query_audit
WHERE
serviceName = 'bigquery.googleapis.com'
AND methodName = 'jobservice.jobcompleted'
AND eventName = 'query_job_completed'
```
