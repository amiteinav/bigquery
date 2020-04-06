# Visualizing BigQuery Audit Logs

## Overview
* Cloud Audit Logs are a collection of logs provided by Google Cloud Platform that provide insight into operational concerns related to your use of Google Cloud services. Here are details about BigQuery specific log information

* Here you will find details on 
  * Setting audit logs stream into BigQuery
  * Querying the information by using queries or datastudio

## Reference
* https://cloud.google.com/bigquery/docs/reference/auditlogs/
* https://github.com/GoogleCloudPlatform/professional-services/tree/master/examples/bigquery-audit-log

## Setting up Audit Logs stream into BigQuery
* Download this repo
```
git clone https://github.com/amiteinav/bigquery-public.git
cd bigquery-public/audit_logs
```
* Set a location (project, dataset and location) to place the logs
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
* Create the dataset if it does not exist 
```
bq mk --location $location \
--dataset ${project}:${auditlog_dataset} 
```
* Create a sink for the *entire* BigQuery logging
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
PWD=`pwd`
sqlfile=${PWD}/bigquery_audit_log.sql
sed  -i 's/DATASET_NAME/'${auditlog_dataset}'/g'  $sqlfile

bq query \
    --use_legacy_sql=false \
    --destination_table=${auditlog_dataset}.${auditlog_table} \
    --display_name='BQ-usage-scheduled-query' \
    --schedule='every 15 minutes' \
    --replace=true \
    --flagfile=$sqlfile
```

## Copying the data source in Data Studio
* Log in to Data Studio and create a copy of this[1] data source.
* Click here[2] for more information on copying data sources.

[1] https://datastudio.google.com/u/2/datasources/10MfID78E_Dyw_n9Cc6gDGUuGyRHrN6dh

[2] https://support.google.com/datastudio/answer/7421646?hl=en&ref_topic=6370331

* There are three derived fields need to be defined in the datasource.
  * totalCached: SUM(numCached);
  * pctCached: totalCached / COUNT(isCached);
  * table: CONCAT(referencedTables.projectId, '.',referencedTables.datasetId,'.',referencedTables.tableId);

* Rename the data source to a name of your choice. 
* Click on "Edit Connection" to navigate to the project, dataset and table of your choice. 
* It should correspond to the materialized table created as a result of step 2 above.

* Click on "Reconnect" located on the top right of the page.

## Creating a dashboard in Data Studio
* Create a copy of this[1] Dashboard.
* After clicking on the Copy button, you will find a message asking you to choose a new data source. 
* Select the data source created in the step above called "Copying the data source in Data Studio"
* Click on create report. Rename the report (dashboard) to a name of your choice.

[1] https://datastudio.google.com/u/2/reporting/1kwNFt05J8_GCju5TBH1v4IlBmmAU74Nu/page/nSaN

 

