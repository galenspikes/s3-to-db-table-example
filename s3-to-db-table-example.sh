#!/bin/bash

echo `date`

######################################
# Set env variables
db_host=localhost
db_user=john
db_name=mydb1
s3_bucket_name=mys3
s3_prefix=mys3prefix
csv_save_location=/home/me/mys3.csv
######################################

/usr/local/bin/aws s3api list-objects --bucket ${s3_bucket_name} --query 'Contents[].{Key: Key, LastModified: LastModified, Size: Size, StorageClass: StorageClass}' --prefix ${s3_prefix} | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' > ${csv_save_location}

psql --echo-queries --echo-hidden -h ${db_host} -U ${db_user} -d ${db_name} -c "truncate table public.s3_table"
psql --echo-queries --echo-hidden -h ${db_host} -U ${db_user} -d ${db_name} -c "alter sequence s3_table_id_seq restart with 1"
psql --echo-queries --echo-hidden -h ${db_host} -U ${db_user} -d ${db_name} -c "\copy public.s3_table(s3_key,last_modified,size,storage_class) from '${csv_save_location}' DELIMITER ',' CSV HEADER"

rm -fv ${csv_save_location}

echo "FINISHED: " `date`
