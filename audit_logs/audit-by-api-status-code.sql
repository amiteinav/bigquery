
/*

* Author: Gal Karanivsky
* Description:
*
* Creates a user friendly view for querying the
* BigQuery query audit logs by API status code
*/

*/


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