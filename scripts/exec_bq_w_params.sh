#!/bin/bash

# https://cloud.google.com/bigquery/docs/parameterized-queries#bigquery_query_params_named-cli

corpus=romeoandjuliet
min_word_count=250

# Example 1
bq query \
--use_legacy_sql=false \
--parameter=corpus::${corpus} \
--parameter=min_word_count:INT64:${min_word_count} \
'SELECT
  word, word_count
FROM
  `bigquery-public-data.samples.shakespeare`
WHERE
  corpus = @corpus
AND
  word_count >= @min_word_count
ORDER BY
  word_count DESC'

# Example 2

bq query \
--use_legacy_sql=false \
--parameter='gender::M' \
--parameter='states:ARRAY<STRING>:["WA", "WI", "WV", "WY"]' \
'SELECT
  name,
  SUM(number) AS count
FROM
  `bigquery-public-data.usa_names.usa_1910_2013`
WHERE
  gender = @gender
  AND state IN UNNEST(@states)
GROUP BY
  name
ORDER BY
  count DESC
LIMIT
  10'

# Example 3

bq query \
--use_legacy_sql=false \
--parameter='ts_value:TIMESTAMP:2016-12-07 08:00:00' \
'SELECT
  TIMESTAMP_ADD(@ts_value, INTERVAL 1 HOUR)'