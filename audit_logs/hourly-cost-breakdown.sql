SELECT
    TIMESTAMP_TRUNC(protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.endTime, HOUR) AS time_window,
    FORMAT('%9.2f',5.0 * (SUM(protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalBilledBytes)/POWER(2, 40))) AS Estimated_USD_Cost
  FROM
    `MYPROJECTID.MYDATASETID.cloudaudit_googleapis_com_data_access_YYYYMMDD`
  WHERE
    protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.eventName = 'query_job_completed'
  GROUP BY time_window
      ORDER BY time_window DESC