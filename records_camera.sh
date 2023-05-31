#!/bin/bash
# :: Please run only with bash ..
# TASKS:
# 1. read files from media
# 2. loop file contents
# 3. connect to datasource
# 4. SQL insert content as hex block per block
TIMEZONE_LOCAL="America/Bogota"
BYTE_BLOCK_LIMIT=1024
LINE_BYTES_SIZE=32
MEDIA_FOLDER="/home/ubuntu/media/"
if [[ "$1" != "" ]]
then
    MEDIA_FOLDER=$1
fi
echo "LIST $MEDIA_FOLDER"
ls -tl $MEDIA_FOLDER
SQL_FOLDER="/home/ubuntu/"
if [[ "$2" != "" ]]
then
    SQL_FOLDER=$2
fi
BACKUP_FOLDER="/home/ubuntu/bk/"
if [[ "$3" != "" ]]
then
    BACKUP_FOLDER=$3
fi
PGSQL_HOST="192.168.20.80"
PGSQL_USER="spiadbadmin"
PGSQL_DBNAME="spiaview"
PGSQL_PORT=5432
PGSQL_COLUMN="content_block, record_offset"
PGSQL_PARENT_COLUMN="device_key, file_stamp, mime_type, temp_file, orientation"
PGSQL_CROSS_COLUMN="file_key, record_key"
PGSQL_TABLE_NAME="records"
PGSQL_TABLE_PARENT_NAME="files"
PGSQL_TABLE_CROSS_NAME="file_records"
PGSQL_TABLE_SEQUENCE="records_record_id_seq"
PGSQL_TABLE_PARENT_SEQUENCE="files_file_id_seq"
TEMP_INSERT_FILE="temp_insert.sql"
TEMP_SELECT_FILE="temp_select.sql"
TEMP_SELECT_RESULT="temp_select_result.tmp"
{
  list_media_files=($(find "$MEDIA_FOLDER" -type f -regex '.*\(.jpeg\|.h265\)$'))
  records_timestamp=$(date +'%Y-%m-%d %H:%M:%S')
  echo "=== SCANNING MEDIA FILES ($records_timestamp) ==="
  echo "${list_media_files[*]}"
} || {
  echo "Error! on list_media_files $MEDIA_FOLDER"
  exit
}
echo "=== START READING FILES ==="
for file in ${list_media_files[*]}
do
    {
        file_key="sq1.last_value"
        # if [[ "$file" != *"_video" ]] && [[ "$file" != *"_image" ]] && [[ "$file" != *".h265" ]]
        if [[ "$file" != *".h265" ]]
        then
            echo "file rejected: $file"
            continue
        fi
        input=$file
        if [[ "$file" != "$MEDIA_FOLDER"* ]]
        then
            input=$MEDIA_FOLDER$file
        fi
        if test -f "$input"
        then
            echo "$input exists."
        else
            echo "FAILURE: $input Not found!"
            continue
        fi
        line_offset=0
        # record_offset=0
        IFS='/' read -ra file_name_split <<< "$file"
        device_id='00030efafb4bd16a7c000400'
        timestamp=$(date '+%s')"000"
        orientation='undefined'
        if [[ "$file" != "file_raw" ]]
        then
            echo "file_name_split: ${file_name_split[*]}"
            {
              device_index=$((-2))
              device_id=${file_name_split[device_index]}
            }||{
              echo "ERROR in (file::device_id): ${file_name_split[*]}"
              device_id='00030efafb4bd16a7c000400'
            }
            {
              timestamp_index=$((-1))
              IFS='.' read -ra file_date_split <<< "${file_name_split[timestamp_index]}"
              timestamp_index=$((-2))
              file_split_timestamp=${file_date_split[timestamp_index]}
              IFS='_' read -ra file_name_split_timestamp <<< "$file_split_timestamp"
              timestamp_index=$((-3))
              timestamp=${file_name_split_timestamp[timestamp_index]}
              datetime_format="${timestamp:0:10} ${timestamp:10:2}:${timestamp:12:2}:${timestamp:14:2}"
              timestamp=$(env TZ="${TIMEZONE_LOCAL}" date -d "${datetime_format} UTC" '+%s')
            } || {
              echo "ERROR in (file::timestamp) : ${file_name_split[*]}"
              timestamp=$(env TZ="${TIMEZONE_LOCAL}" date '+%s')"000"
            }
            if [[ "$timestamp" == "" ]]
            then
              timestamp=$(env TZ="${TIMEZONE_LOCAL}" date '+%s')"000"
            fi
            {
              if [[ "$file" == *"_front"* ]]
              then
                orientation="front"
              elif [[ "$file" == *"_rear"* ]]
              then
                orientation="rear"
              else
                orientation='both'
              fi
              echo "$file cam is ($orientation)."
            } || {
              orientation='both'
            }
        fi
        # BEGIN: validate mime-type
        #mime_type=$(file --mime-type $input)
        #IFS=': ' read -ra mime_type <<< $mime_type
        #mime_type="${mime_type[1]}"
        # END: validate mime-type
        mime_type="image/jpeg"
        if [[ "$file" == *"_video"* ]] || [[ "$file" == *".h265" ]]
        then
          mime_type="application/octet-stream"
          echo ".... $file is a video ...."
        elif [[ "$file" == *"_image"* ]] || [[ "$file" == *".jpeg" ]]
        then
          echo ".... $file is an image ...."
        fi
        # BEGIN: validate temp_file
        sql_select_temp_where="WHERE temp_file = '$file' AND mime_type like '$mime_type'"
        sql_select_temp="SELECT * FROM $PGSQL_TABLE_PARENT_NAME $sql_select_temp_where;"
        echo "$sql_select_temp" > "$SQL_FOLDER$TEMP_SELECT_FILE"
        echo "=== SCANNING $TEMP_INSERT_FILE ==="
        temp_select_file_cat=$(cat "$SQL_FOLDER$TEMP_INSERT_FILE")
        echo "$temp_select_file_cat"
        #cat $SQL_FOLDER$TEMP_SELECT_FILE >> $SQL_FOLDER"inserts_records.sql"
        {
          psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f "$SQL_FOLDER$TEMP_SELECT_FILE" > "$SQL_FOLDER$TEMP_SELECT_RESULT"
        } || {
          echo "[p]SQL ERROR: (SELECT $PGSQL_TABLE_PARENT_NAME ...) >> $temp_select_file_cat"
        }
        result=""; while read -r line; do result="$result$line;"; done < $SQL_FOLDER$TEMP_SELECT_RESULT
        if [[ "$result" != *"(0 rows)"* ]]
        then
          IFS=';' read -ra results <<< "$result"
          end_rows=${#results}
          for (( i = 2; i < end_rows; i++ ))
          do
            IFS=' | ' read -ra row <<< "${results[$i]}"
            if [[ "${row[0]}" != "" ]]
            then
              file_id="${row[0]}"
              file_key=$file_id
              echo "file_key exists: $file_id"
              break
            fi
          done
        fi
        # END: validate temp_file
        echo "()=>$input [$device_id, $timestamp,$mime_type,$file,$orientation] reading ..."
        echo ""
        if [[ "$file_key" == "" ]] || [[ "$file_key" == "sq1.last_value" ]]
        then
          # /1000
          sql_insert_file="INSERT INTO $PGSQL_TABLE_PARENT_NAME ($PGSQL_PARENT_COLUMN)"
          format_timestamp="to_timestamp($timestamp)"
          table_file_values="'$device_id', $format_timestamp, '$mime_type', '$file', '$orientation'"
          sql_insert_file="$sql_insert_file VALUES ($table_file_values);"
          echo "$sql_insert_file" > "$SQL_FOLDER$TEMP_INSERT_FILE"
          echo "=== CHECK $TEMP_INSERT_FILE ==="
          temp_insert_file_cat=$(cat "$SQL_FOLDER$TEMP_INSERT_FILE")
          echo "$temp_insert_file_cat"
          cat "$SQL_FOLDER$TEMP_INSERT_FILE" >> "${SQL_FOLDER}inserts_records.sql"
          {
            psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f "$SQL_FOLDER$TEMP_INSERT_FILE"
          } || {
            echo "[p]SQL ERROR: (INSERT INTO $PGSQL_TABLE_PARENT_NAME ...) >> $temp_insert_file_cat"
          }
        else
          echo "validate temp_file: ${results[*]}"
        fi
        {
            lines_insert=($(xxd -p "$input"))
            echo "== WARNING: INSERT FROM HEX STRING : ${lines_insert[0]} =="
            # lines_insert=($(cat "$input"))
            line_count=0
            block=""
            # block_count=32
            declare -a block_inserts
            # lines="";
            for line in ${lines_insert[*]}
            do
#              lines="$lines$line"
#           done
#              if ((${#block} < (BYTE_BLOCK_LIMIT*2)))
#              then
#                 block="$block$line"
#                 continue
#              fi
              echo ">>> LINE [$line_count] ?? \"$line\""
              if ((line_count < LINE_BYTES_SIZE))
              then
                echo ">>> ADD LINE [$line_count]: \"$line\""
                block="$block$line"
                line_count=$((line_count + 1))
                continue
              fi
              block_inserts+=("$block")
              blocks_size=${#block_inserts}
              last_block=$((blocks_size - 1))
              echo "ADD BLOCK: \"${block_inserts[last_block]}\""
              block="$line"
              line_count=1
            done
            if ((line_count < LINE_BYTES_SIZE)) && ((line_count > 0))
            then
                block_inserts+=("$block")
            fi
            record_offset=0
            for line in ${block_inserts[*]}
            do
              block=$line
              echo "-> ENTIRE MODE: block=\"$block\" offset=$record_offset"
              # "... lines=\"\$lines\$line\""
              # block=$lines
              sql_insert_block="INSERT INTO $PGSQL_TABLE_NAME ($PGSQL_COLUMN) VALUES ('$block', $record_offset);"
              echo "$sql_insert_block" > "$SQL_FOLDER$TEMP_INSERT_FILE"
              sql_select_cross="SELECT $file_key, sq2.last_value"
              sql_select_cross="$sql_select_cross FROM $PGSQL_TABLE_PARENT_SEQUENCE sq1, $PGSQL_TABLE_SEQUENCE sq2;"
              sql_insert_cross="INSERT INTO $PGSQL_TABLE_CROSS_NAME ($PGSQL_CROSS_COLUMN) $sql_select_cross"
              echo "$sql_insert_cross" >> "$SQL_FOLDER$TEMP_INSERT_FILE"
              echo "=== CHECK $TEMP_INSERT_FILE (2) ==="
              # cat $SQL_FOLDER$TEMP_INSERT_FILE
              temp_insert_file_cat=$(cat "$SQL_FOLDER$TEMP_INSERT_FILE")
              echo "$temp_insert_file_cat"
              #cat $SQL_FOLDER$TEMP_INSERT_FILE >> $SQL_FOLDER"inserts_records.sql"
              {
                psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f $SQL_FOLDER$TEMP_INSERT_FILE
              } || {
                echo "[p]SQL ERROR: (INSERT INTO $PGSQL_TABLE_NAME || $PGSQL_TABLE_CROSS_NAME ...)"
                echo " >> $temp_insert_file_cat"
              }
              record_offset=$((record_offset + 1))
              block=""
              # line_count=0
            done
            if test -f "$input"
            then
                echo "$input exists for RM."
                mv $input $BACKUP_FOLDER
            else
                echo "RM: $input Not found!"
                continue
            fi
        } || {
            echo "Error! on Subprocess [block_inserts] $input:$record_offset"
            echo ""
        }
    } || {
      echo "Error! on Process $input"
      echo ""
    }
done
echo "LIST $BACKUP_FOLDER"
ls -tl "$BACKUP_FOLDER"
sudo cp -r "$MEDIA_FOLDER" "$BACKUP_FOLDER"
echo "LIST ${BACKUP_FOLDER}media"
ls -tl "${BACKUP_FOLDER}media"
sudo rm -Rf ${MEDIA_FOLDER}*