# 
## Creating an integer partition
```
bq mk \
--range_partitioning=customer_id,0,100,10 \
${DATASET}.${TABLE} \
"customer_id:integer,value:integer"
```

### Verify a table is partitioned on an integer column 
```
bq show \
--format=prettyjson \
my_dataset.my_table
```

### Writing to an integer range partitioned table
```
bq query --nouse_legacy_sql \
--destination_table=Demos.my_table_int_partitioning \
--replace \
'SELECT   value AS customer_id,  value+1 AS value FROM   UNNEST(GENERATE_ARRAY(-5, 110, 5)) AS value'
```
### Querying an integer range partitioned table
This will scan 96 Bytes
```
bq query --nouse_legacy_sql \
'SELECT * FROM Demos.my_table_int_partitioning WHERE customer_id BETWEEN 30 AND 50'
```
This will scan 128 Bytes
```
bq query --nouse_legacy_sql \
'SELECT * FROM Demos.my_table_int_partitioning WHERE customer_id BETWEEN 20 AND 50'
```