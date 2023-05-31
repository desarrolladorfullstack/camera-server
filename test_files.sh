#!/bin/bash
file_origin="2023-05-17180432_video_rear.h265"
if [[ "$1" != "" ]]
then
    file_origin=$1
fi
file_records="file_raw_temp_file_2023_05_17_003.h265"
if [[ "$2" != "" ]]
then
    file_records=$2
fi
lines_origin_array=($(xxd -p "$file_origin"))
lines_records_array=($(xxd -p "$file_records"))
lines_origin=""
for line in ${lines_origin_array[*]}
do
  lines_origin="$lines_origin$line"
done
lines_records=""
for records in ${lines_records_array[*]}
do
  lines_records="$lines_records$records"
done
if [[ "$lines_records" == "$lines_origin" ]]
then
  echo "SAME CONTENT!"
elif [[ "$lines_records" == "$lines_origin"* ]]
then
  echo "INITIAL CONTENT FROM ORIGIN!!"
elif [[ "$lines_records" == *"$lines_origin"* ]]
then
  echo "CONTENT BETWEEN ORIGIN!!!"
fi