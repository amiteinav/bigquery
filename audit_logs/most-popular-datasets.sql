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