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
export auditlog_table=bigquery_audit_log
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

* Run the following command to schedule the query to run every 15 minutes
```
query=`cat bigquery_audit_log.sql`
bq query \
    --use_legacy_sql=false \
    --destination_table=${auditlog_dataset}.${auditlog_table} \
    --display_name='BigQuery Usage Scheduled Query' \
    --replace=true \
    '`echo $query`'
```

