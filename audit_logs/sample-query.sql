  #standardSQL
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