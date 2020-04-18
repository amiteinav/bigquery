
# Filftering based on CIDR
Below are queries to select all rows with IP that is matching a given CIDR pattern

## Table structure
Two columns:
1. IP as a string
2. IP as an integer

## Creating VMs to create the table in bigquery
- The plan is to create VM that will create csv files with IP in string and IP as an integer.
- The are 4,294,967,296 (2^32) address - so it might take a while to create a record for each one if we use our PC.
- example: a single thread for creating 2^17 address takes about 3 seconds. so it would take 3*(2^15) seconds (27 hours) to complete the task
- we will instead do it in 255 threads - so each thread will create 16,843,009 addresses (2^24). that would take ~7 minutes to finish


* Run these commands to create 3 VMs with many processors
```
PROJECT=`gcloud config get-value project`
NETWORK=default

gcloud beta compute --project=$PROJECT instances create ip-manufactor-vm-1 --zone=us-central1-a --machine-type=n1-standard-96  --scopes=https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.write_only --tags=ip-manufactor-vm --image=ubuntu-1604-xenial-v20200407 --image-project=ubuntu-os-cloud --boot-disk-size=200GB --boot-disk-type=pd-ssd


gcloud beta compute --project=$PROJECT instances create ip-manufactor-vm-2 --zone=us-central1-a --machine-type=n1-standard-96  --scopes=https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.write_only --tags=ip-manufactor-vm --image=ubuntu-1604-xenial-v20200407 --image-project=ubuntu-os-cloud --boot-disk-size=200GB --boot-disk-type=pd-ssd


gcloud beta compute --project=$PROJECT instances create ip-manufactor-vm-3 --zone=us-central1-a --machine-type=n1-standard-96  --scopes=https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.write_only --tags=ip-manufactor-vm --image=ubuntu-1604-xenial-v20200407 --image-project=ubuntu-os-cloud --boot-disk-size=200GB --boot-disk-type=pd-ssd
```

* Create a FW to access these VMs via ssh (change the source-ranges to your desktop if you like)

```
PROJECT=`gcloud config get-value project`
NETWORK=default
gcloud compute --project=${PROJECT} firewall-rules create fw-allow-ssh-ip-manufactor \
 --direction=INGRESS --priority=100 --network=${NETWORK} \
 --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0 \
 --target-tags=ip-manufactor-vm
```

* On server 1
```
cd bigquery-public/CIDR-calc/
bash create_all_ipv4_range 0 85
```
* On server 2
```
cd bigquery-public/CIDR-calc/
bash create_ipv4_range.sh 86 171
```
* On server 3
```
cd bigquery-public/CIDR-calc/
bash create_ipv4_range.sh 172 255
```

I uploaded the files that where created into Google Cloud Storage and then used the BigQuery console to upload to a table.

## OPTION 1 - Just a query - slowest
This option is slowest among 3. because some NET functions are done several times

```
SELECT count(*) IPs_in_CIDR
FROM `PROJECT.DATASET.allipv4`
WHERE
  ipv4_as_int between 
  (SELECT NET.IPV4_TO_INT64(NET.IP_TRUNC(NET.IP_FROM_STRING(SPLIT('192.168.0.1/8', '/')[OFFSET(0)]),CAST(SPLIT('192.168.0.1/8', '/')[OFFSET(1)] AS int64))))
  and
  (SELECT NET.IPV4_TO_INT64(NET.IP_TRUNC(NET.IP_FROM_STRING(SPLIT('192.168.0.1/8', '/')[OFFSET(0)]),CAST(SPLIT('192.168.0.1/8', '/')[OFFSET(1)] AS int64)))) +
  (select CAST(POW(2,32-CAST(SPLIT('192.168.0.1/8', '/')[OFFSET(1)] AS int64)) AS INT64))
```

## OPTION 2 - with DECLARE and SET - faster
This option is faster than option 1. because some NET functions are done once.

```
DECLARE MAX_IP_IN_CIDR_RANGE INT64;
DECLARE MIN_IP_IN_CIDR_RANGE INT64;
DECLARE STRING_IP STRING;
DECLARE INT_RANGE INT64;
DECLARE CIDR_RANGE STRING;
DECLARE TOTAL_ADDRESSES INT64;

SET CIDR_RANGE = '192.168.0.1/20';
SET STRING_IP = SPLIT(CIDR_RANGE, '/')[OFFSET(0)];
SET INT_RANGE = cast(SPLIT(CIDR_RANGE, '/')[OFFSET(1)] as INT64);
SET TOTAL_ADDRESSES = CAST(POW(2,32-INT_RANGE) AS INT64);
SET MIN_IP_IN_CIDR_RANGE = NET.IPV4_TO_INT64(NET.IP_TRUNC(NET.IP_FROM_STRING(STRING_IP),INT_RANGE));
SET MAX_IP_IN_CIDR_RANGE = MIN_IP_IN_CIDR_RANGE + TOTAL_ADDRESSES;

  
SELECT count(*) IPs_in_CIDR
FROM `PROJECT.DATASET.allipv4`
WHERE
  ipv4_as_int BETWEEN MIN_IP_IN_CIDR_RANGE AND MAX_IP_IN_CIDR_RANGE
 ```

## OPTION 3 - smallest footprint
* This option has the smallest footprint and minimal compute operations
```
DECLARE CIDR_STRING STRING DEFAULT ('192.168.0.1/20');
DECLARE STRING_IP STRING DEFAULT(REGEXP_EXTRACT(CIDR_STRING, r'(.*)/' ));
DECLARE INT_RANGE INT64 DEFAULT (cast(REGEXP_EXTRACT(CIDR_STRING, r'/(.*)') AS INT64));
DECLARE MIN_IP_IN_CIDR_RANGE INT64 DEFAULT(NET.IPV4_TO_INT64(NET.IP_TRUNC(NET.IP_FROM_STRING(STRING_IP),INT_RANGE)));
DECLARE TOTAL_ADDRESSES INT64 DEFAULT (CAST(POW(2,32-INT_RANGE) AS INT64));
DECLARE MAX_IP_IN_CIDR_RANGE INT64 DEFAULT(MIN_IP_IN_CIDR_RANGE + TOTAL_ADDRESSES);

SELECT ipv4_as_int
FROM `PROJECT.DATASET.allipv4``
WHERE
  ipv4_as_int BETWEEN MIN_IP_IN_CIDR_RANGE AND (MAX_IP_IN_CIDR_RANGE-1)
LIMIT 1
```

* If there is no option to use integer representation - use this:
```

DECLARE CIDR_STRING STRING DEFAULT ('192.168.0.1/20');
DECLARE STRING_IP STRING DEFAULT(REGEXP_EXTRACT(CIDR_STRING, r'(.*)/' ));
DECLARE INT_RANGE INT64 DEFAULT (cast(REGEXP_EXTRACT(CIDR_STRING, r'/(.*)') AS INT64));
DECLARE MIN_IP_IN_CIDR_RANGE INT64 DEFAULT(NET.IPV4_TO_INT64(NET.IP_TRUNC(NET.IP_FROM_STRING(STRING_IP),INT_RANGE)));
DECLARE TOTAL_ADDRESSES INT64 DEFAULT (CAST(POW(2,32-INT_RANGE) AS INT64));
DECLARE MAX_IP_IN_CIDR_RANGE INT64 DEFAULT(MIN_IP_IN_CIDR_RANGE + TOTAL_ADDRESSES);

SELECT ipv4_as_int
FROM `PROJECT.DATASET.allipv4``
WHERE
  NET.IPV4_TO_INT64(NET.IP_FROM_STRING(ipv4_as_string)) BETWEEN MIN_IP_IN_CIDR_RANGE AND (MAX_IP_IN_CIDR_RANGE-1)
LIMIT 1

```

