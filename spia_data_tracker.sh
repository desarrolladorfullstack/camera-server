#!/bin/bash
# :: Please run only with bash ..
# TASKS:
# 1. read files from data
# 2. loop file contents
# 3. connect to datasource
# 4. SQL insert content as hex block per block
TIMEZONE_LOCAL="America/Bogota"
TZ_FACTOR=$((5 * 60 * 60))
BYTE_BLOCK_LIMIT=1024
LINE_BYTES_SIZE=32
SPIA_DATA_FOLDER="/home/ubuntu/spia/"
if [[ "$1" != "" ]]
then
    SPIA_DATA_FOLDER=$1
fi
echo "LIST $SPIA_DATA_FOLDER"
ls -tl $SPIA_DATA_FOLDER
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
PGSQL_PARENT_COLUMNS="device_key, property_key, property_stamp, parent_event"
PGSQL_TABLE_PARENT_NAME="device_properties"
PGSQL_COLUMNS="event_key, property_value"
PGSQL_TABLE_NAME="properties"
PGSQL_VIEW_NAME="view_property_id_by"
PGSQL_TABLE_SEQUENCE="properties_property_id_seq"
PGSQL_OTHER_PARENT_COLUMNS="file_key, property_key, property_stamp, parent_event"
PGSQL_TABLE_OTHER_PARENT_NAME="file_properties"
PGSQL_TABLE_PARENT_SEQUENCE="files_file_id_seq"
TEMP_INSERT_FILE="temp_insert_spia.sql"
TEMP_SELECT_FILE="temp_select_spia.sql"
TEMP_SELECT_RESULT="temp_select_result_spia.tmp"
{
  list_spia_data_files=($(find "$SPIA_DATA_FOLDER" -type f -regex '.*\(.spia\)$'))
  tracker_timestamp=$(date +'%Y-%m-%d %H:%M:%S')
  echo "=== SCANNING SPIA DATA FILES ($tracker_timestamp) ==="
  echo "${list_spia_data_files[*]}"
} || {
  echo "Error! on list_spia_data_files $SPIA_DATA_FOLDER"
  exit
}
echo "=== START READING FILES ==="
for file in ${list_spia_data_files[*]}
do
    {
#        file_key="sq1.last_value"
        # if [[ "$file" != *"_video" ]] && [[ "$file" != *"_image" ]] && [[ "$file" != *".h265" ]]
        if [[ "$file" != *".spia" ]]
        then
            echo "file rejected: $file"
            continue
        fi
        input=$file
        if [[ "$file" != "$SPIA_DATA_FOLDER"* ]]
        then
            input=$SPIA_DATA_FOLDER$file
        fi
        if test -f "$input"
        then
            echo "$input exists."
        else
            echo "FAILURE: $input Not found!"
            continue
        fi
#        line_offset=0
        # record_offset=0
        IFS='/' read -ra file_name_split <<< "$file"
        device_id='undefined'
        timestamp=$(date '+%s')"000"
        parent_event='00'
        if [[ "$file" != "file_raw" ]]
        then
            echo "file_name_split: ${file_name_split[*]}"
            {
              device_index=$((-2))
              device_id=${file_name_split[device_index]}
            }||{
              echo "ERROR in (file::device_id): ${file_name_split[*]}"
              device_id='undefined'
            }
            {
              timestamp_index=$((-1))
              IFS='.' read -ra file_date_split <<< "${file_name_split[timestamp_index]}"
              timestamp_index=$((-2))
#              file_split_timestamp=${file_date_split[timestamp_index]}
#              IFS='_' read -ra file_name_split_timestamp <<< "$file_split_timestamp"
#              timestamp_index=$((-3))
#              timestamp=${file_name_split_timestamp[timestamp_index]}
              timestamp=${file_date_split[timestamp_index]}
#              datetime_format="${timestamp:0:10} ${timestamp:10:2}:${timestamp:12:2}:${timestamp:14:2}"
#              timestamp=$(env TZ="${TIMEZONE_LOCAL}" date -d "${datetime_format} UTC" '+%s')
            } || {
              echo "ERROR in (file::timestamp) : ${file_name_split[*]}"
              timestamp=$(env TZ="${TIMEZONE_LOCAL}" date '+%s')"000"
            }
            if [[ "$timestamp" == "" ]]
            then
              timestamp=$(env TZ="${TIMEZONE_LOCAL}" date '+%s')"000"
            fi
            {
              input_event_id_cat=($(cat "$input"))
              echo "event_id?:${input_event_id_cat[0]}=>${input_event_id_cat[1]}"
              parent_event=${input_event_id_cat[0]}
              echo "$file event_id is ($parent_event)."
            } || {
              echo "ERROR in (file::event_id) : ${file_name_split[*]}"
              parent_event='30'
            }
        fi
        # BEGIN: validate timestamp
        #mime_type=$(file --mime-type $input)
        #IFS=': ' read -ra mime_type <<< $mime_type
        #mime_type="${mime_type[1]}"
        # END: validate mime-type
#        mime_type="image/jpeg"
#        if [[ "$file" == *"_video"* ]] || [[ "$file" == *".h265" ]]
#        then
#          mime_type="application/octet-stream"
#          echo ".... $file is a video ...."
#        elif [[ "$file" == *"_image"* ]] || [[ "$file" == *".jpeg" ]]
#        then
#          echo ".... $file is an image ...."
#        fi
        echo "=== SCANNING $TEMP_INSERT_FILE ==="
        temp_select_file_cat=$(cat "$SQL_FOLDER$TEMP_INSERT_FILE")
        echo "$temp_select_file_cat"
        # BEGIN: validate timestamp
        format_timestamp="to_timestamp($timestamp)"
        sql_select_temp_where="WHERE EXTRACT(EPOCH FROM property_stamp::timestamp) = $timestamp"
        sql_select_temp_where_and="AND parent_event IN (decode('$parent_event', 'hex'))"
        sql_select_temp_where=$(printf "%s \n%s" "$sql_select_temp_where" "$sql_select_temp_where_and")
        sql_select_temp="SELECT COUNT(*) AS num_properties"
        sql_select_from="FROM $PGSQL_TABLE_PARENT_NAME"
        sql_select_temp=$(printf "%s \n%s" "$sql_select_temp" "$sql_select_from")
        sql_select_temp=$(printf "%s \n%s" "$sql_select_temp" "$sql_select_temp_where;")
        echo "$sql_select_temp" > "$SQL_FOLDER$TEMP_SELECT_FILE"
        echo "=== SCANNING $TEMP_SELECT_FILE ==="
        temp_select_file_cat=$(cat "$SQL_FOLDER$TEMP_SELECT_FILE")
        echo "$temp_select_file_cat"
        #cat $SQL_FOLDER$TEMP_SELECT_FILE >> $SQL_FOLDER"inserts_records.sql"
#        echo "psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f $SQL_FOLDER$TEMP_SELECT_FILE > $SQL_FOLDER$TEMP_SELECT_RESULT"
        ### QUERY validate timestamp
        {
          psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f "$SQL_FOLDER$TEMP_SELECT_FILE" > "$SQL_FOLDER$TEMP_SELECT_RESULT"
          printf "%s \n%s" "== $SQL_FOLDER$TEMP_SELECT_FILE ==" "$temp_select_file_cat"
        } || {
          echo "[p]SQL ERROR: (SELECT $PGSQL_TABLE_PARENT_NAME ...) >> $temp_select_file_cat"
        }
        echo "$temp_select_file_cat" > "${SQL_FOLDER}query_select_spia.sql"
        result=""; while read -r line; do result="$result$line;"; done < $SQL_FOLDER$TEMP_SELECT_RESULT
        #echo "result trim(): $result"
        if [[ "$result" != *"(0 rows)"* ]] && [[ "$result" != *";0;(1 row)"* ]] && [[ "$result" != *";;(1 row)"* ]]
        then
          IFS=';' read -ra results <<< "$result"
          end_rows=${#results}
          for (( i = 2; i < end_rows; i++ ))
          do
            IFS=' | ' read -ra row <<< "${results[$i]}"
            # && [[ "${row[0]}" != "0" ]] && [[ "${row[0]}" != *"(0 rows)"* ]]
            if [[ "${row[0]}" != "" ]] 
            then
#              file_id="${row[0]}"
#              file_key=$file_id
              timestamp=$((timestamp + 1))
              echo "timestamp exists. change milliseconds: $timestamp"
              break
            fi
          done
        fi
        # END: validate temp_file
#        echo "()=>$input [$device_id, $timestamp,$mime_type,$file,$orientation] reading ..."
#        echo ""
#        if [[ "$file_key" == "" ]] || [[ "$file_key" == "sq1.last_value" ]]
#        then
#          # /1000
#          sql_insert_file="INSERT INTO $PGSQL_TABLE_PARENT_NAME ($PGSQL_PARENT_COLUMN)"
#          format_timestamp="to_timestamp($timestamp)"
#          table_file_values="'$device_id', $format_timestamp, '$mime_type', '$file', '$orientation'"
#          sql_insert_file="$sql_insert_file VALUES ($table_file_values);"
#          echo "$sql_insert_file" > "$SQL_FOLDER$TEMP_INSERT_FILE"
#          echo "=== CHECK $TEMP_INSERT_FILE ==="
#          temp_insert_file_cat=$(cat "$SQL_FOLDER$TEMP_INSERT_FILE")
#          echo "$temp_insert_file_cat"
#          cat "$SQL_FOLDER$TEMP_INSERT_FILE" >> "${SQL_FOLDER}inserts_records.sql"
#          {
#            psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f "$SQL_FOLDER$TEMP_INSERT_FILE"
#          } || {
#            echo "[p]SQL ERROR: (INSERT INTO $PGSQL_TABLE_PARENT_NAME ...) >> $temp_insert_file_cat"
#          }
#        else
#          echo "validate temp_file: ${results[*]}"
#        fi
        {
            lines_insert=($(cat "$input"))
            echo ""
            echo "== WARNING: INSERT FROM HEX STRING : ${lines_insert[*]} =="
            # lines_insert=($(cat "$input"))
            line_count=0
#            block=""
#            # block_count=32
#            declare -a block_inserts
#            # lines="";
#            for line in ${lines_insert[*]}
#            do
##              lines="$lines$line"
##           done
##              if ((${#block} < (BYTE_BLOCK_LIMIT*2)))
##              then
##                 block="$block$line"
##                 continue
##              fi
#              echo ">>> LINE [$line_count] ?? \"$line\""
#              if ((line_count < LINE_BYTES_SIZE))
#              then
#                echo ">>> ADD LINE [$line_count]: \"$line\""
#                block="$block$line"
#                line_count=$((line_count + 1))
#                continue
#              fi
#              block_inserts+=("$block")
#              blocks_size=${#block_inserts}
#              last_block=$((blocks_size - 1))
#              echo "ADD BLOCK: \"${block_inserts[last_block]}\""
#              block="$line"
#              line_count=1
#            done
#            if ((line_count < LINE_BYTES_SIZE)) && ((line_count > 0))
#            then
#                block_inserts+=("$block")
#            fi
#            record_offset=0
            prop_key=$parent_event
            prop_value='30'
            end_file=0
            for line in ${lines_insert[*]}
            do
              line_count=$((line_count + 1))
#              block=$line
              if [[ $line == "~" ]]
              then
                end_file=1
                line_count=0
                continue
              fi
              if (((line_count%2) == 0))
              then
                prop_value=$line
              else
                prop_key=$line
                if ((end_file == 1))
                then
                  timestamp=$((timestamp + 1))
                  parent_event=$prop_key
                  echo "ADD: Event ($parent_event) in timestamp+ ($timestamp)"
                  end_file=0
                fi
                continue
              fi
              exists_property=0
              property_key="sq.last_value"
              # BEGIN: validate property
              format_timestamp="to_timestamp($timestamp)"
              sql_select_temp_where="WHERE event_key = decode('$prop_key', 'hex')"
              sql_select_temp_where_and="AND property_value = decode('$prop_value', 'hex')"
              sql_select_temp_where=$(printf "%s \n%s" "$sql_select_temp_where" "$sql_select_temp_where_and")
              sql_select_temp="SELECT MAX(property_id) AS property_id"
              sql_select_from="FROM $PGSQL_TABLE_NAME"
              sql_select_temp=$(printf "%s \n%s" "$sql_select_temp" "$sql_select_from")
              sql_select_temp=$(printf "%s \n%s" "$sql_select_temp" "$sql_select_temp_where;")
              echo "$sql_select_temp" > "$SQL_FOLDER$TEMP_SELECT_FILE"
#              echo "=== SCANNING $TEMP_INSERT_FILE ==="
#              temp_select_file_cat=$(cat "$SQL_FOLDER$TEMP_INSERT_FILE")
#              echo "$temp_select_file_cat"
              #cat $SQL_FOLDER$TEMP_SELECT_FILE >> $SQL_FOLDER"inserts_records.sql"
#              echo "psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f $SQL_FOLDER$TEMP_SELECT_FILE > $SQL_FOLDER$TEMP_SELECT_RESULT"
              ### QUERY validate property
              {
                psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f "$SQL_FOLDER$TEMP_SELECT_FILE" > "$SQL_FOLDER$TEMP_SELECT_RESULT"
                temp_psql_result=$(cat "$SQL_FOLDER$TEMP_SELECT_RESULT")
                temp_psql_result_rows=${#temp_psql_result}
                printf "%s \n%s\n" "== $SQL_FOLDER$TEMP_SELECT_FILE ==" "total: $temp_psql_result_rows"
              } || {
                echo "[p]SQL ERROR: (SELECT $PGSQL_TABLE_NAME ... validate) >> $temp_select_file_cat"
              }
              echo "$temp_select_file_cat" >> "${SQL_FOLDER}query_select_spia.sql"
              result=""; while read -r line; do result="$result$line;"; done < $SQL_FOLDER$TEMP_SELECT_RESULT              
              # echo "result trim(2): $result"
              if [[ "$result" != *"(0 rows)"* ]] && [[ "$result" != *";0;(1 row)"* ]] && [[ "$result" != *";;(1 row)"* ]]
              then
                IFS=';' read -ra results <<< "$result"
                end_rows=${#results}
                for (( i = 2; i < end_rows; i++ ))
                do
                  IFS=' | ' read -ra row <<< "${results[$i]}"
                  if [[ "${row[0]}" != "" ]]
                  then
                    property="${row[0]} ${row[1]}"
                    property_id="${row[0]}"
                    property_key=$property_id
                    echo "property exists. $property_key"
                    echo ">>> $property"
                    break
                  fi
                done
              fi
              # END: validate property
              # BEGIN: validate device_property
              format_timestamp="to_timestamp($timestamp)"
              sql_select_temp_join="WHERE"
              sql_select_temp_join=$(printf "%s \n%s" "$sql_select_temp_join" " device_key IN ('$device_id')")
              sql_select_temp_join_and="AND parent_event IN (decode('$parent_event', 'hex'))"
              sql_select_temp_join=$(printf "%s \n%s" "$sql_select_temp_join" "$sql_select_temp_join_and")
              # sql_select_temp_join_and="AND dp.property_key = p.property_id"
              # sql_select_temp_join=$(printf "%s \n%s" "$sql_select_temp_join" "$sql_select_temp_join_and")
              sql_select_temp_join_and="AND EXTRACT(EPOCH FROM property_stamp::timestamp) = $timestamp"
              sql_select_temp_join=$(printf "%s \n%s" "$sql_select_temp_join" "$sql_select_temp_join_and")
              sql_select_temp_where="AND event_key = decode('$prop_key', 'hex')"
              sql_select_temp_where_and="AND property_value = decode('$prop_value', 'hex')"
              sql_select_temp_where=$(printf "%s \n%s" "$sql_select_temp_where" "$sql_select_temp_where_and")
              sql_select_temp_where=$(printf "%s \n%s" "$sql_select_temp_join" "$sql_select_temp_where")
              sql_select_fields="property_id"
              sql_select_fields_stamp="EXTRACT(EPOCH FROM dp.property_stamp::timestamp)"
              sql_select_from="FROM $PGSQL_VIEW_NAME"
              sql_select_temp=$(printf "%s \n%s" "SELECT $sql_select_fields" "$sql_select_from")
              sql_select_temp=$(printf "%s \n%s" "$sql_select_temp" "$sql_select_temp_where")
              sql_select_temp=$(printf "%s \n%s" "$sql_select_temp" "LIMIT 1;")
              echo "$sql_select_temp" > "$SQL_FOLDER$TEMP_SELECT_FILE"
              echo "=== SCANNING $TEMP_SELECT_FILE ==="
              temp_select_file_cat=$(cat "$SQL_FOLDER$TEMP_SELECT_FILE")
              echo "$temp_select_file_cat"
              #cat $SQL_FOLDER$TEMP_SELECT_FILE >> $SQL_FOLDER"inserts_records.sql"
#              echo "psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f $SQL_FOLDER$TEMP_SELECT_FILE > $SQL_FOLDER$TEMP_SELECT_RESULT"
              ### QUERY validate device_property
              {
                psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f "$SQL_FOLDER$TEMP_SELECT_FILE" > "$SQL_FOLDER$TEMP_SELECT_RESULT"
                temp_psql_result=$(cat "$SQL_FOLDER$TEMP_SELECT_RESULT")
                temp_psql_result_rows=${#temp_psql_result}
                printf "%s \n%s\n" "== $SQL_FOLDER$TEMP_SELECT_FILE ==" "total: $temp_psql_result_rows"
              } || {
                echo "[p]SQL ERROR: (SELECT $PGSQL_TABLE_PARENT_NAME ... validate) >> $temp_select_file_cat"
              }
              echo "$temp_select_file_cat" >> "${SQL_FOLDER}query_select_spia.sql"
              result=""; while read -r line; do result="$result$line;"; done < $SQL_FOLDER$TEMP_SELECT_RESULT
              # echo "result trim(3): $result"
              if [[ "$result" != *"(0 rows)"* ]] && [[ "$result" != *";0;(1 row)"* ]] && [[ "$result" != *";;(1 row)"* ]]
              then
                echo "validate device_property (1)"
                IFS=';' read -ra results <<< "$result"
                end_rows=${#results}
                for (( i = 2; i < end_rows; i++ ))
                do
                  IFS=' | ' read -ra row <<< "${results[$i]}"
                  if [[ "${row[0]}" != "" ]]
                  then
                    echo "validate device_property (2)"
                    device_property="${row[0]} ${row[1]}"
                    echo "device_property exists. $device_property, SKIP !"
                    exists_property=1
#                    break
                  fi
                done
              fi
              # END: validate device_property
              if ((exists_property == 0))
              then
                echo "-> ENTIRE MODE: prop_key=\"$prop_key\" prop_value=\"$prop_value\""
                # "... lines=\"\$lines\$line\""
                # block=$lines
                sql_insert_block="INSERT INTO $PGSQL_TABLE_NAME"
                sql_insert_block_values="VALUES (decode('$prop_key', 'hex'), decode('$prop_value', 'hex'));"
                sql_insert_block=$(printf "%s \n%s" "$sql_insert_block ($PGSQL_COLUMNS)" "$sql_insert_block_values")
                printf "%s\n" "$sql_insert_block" > "$SQL_FOLDER$TEMP_INSERT_FILE"
                format_timestamp="to_timestamp($timestamp + $TZ_FACTOR)"
                sql_select_parent="SELECT '$device_id', $property_key"
                sql_select_parent_and=", $format_timestamp"
                sql_select_parent=$(printf "%s \n%s" "$sql_select_parent" "$sql_select_parent_and")
                sql_select_parent_and=", decode('$parent_event', 'hex')"
                sql_select_parent=$(printf "%s \n%s" "$sql_select_parent" "$sql_select_parent_and")
                sql_select_parent=$(printf "%s \n%s" "$sql_select_parent" "FROM $PGSQL_TABLE_SEQUENCE sq;")
                sql_insert_cross="INSERT INTO $PGSQL_TABLE_PARENT_NAME ($PGSQL_PARENT_COLUMNS)"
                sql_insert_cross=$(printf "%s \n%s" "$sql_insert_cross" "$sql_select_parent")
                echo "$sql_insert_cross" >> "$SQL_FOLDER$TEMP_INSERT_FILE"
                echo "=== CHECK $TEMP_INSERT_FILE ==="
                # cat $SQL_FOLDER$TEMP_INSERT_FILE "(2)"
                temp_insert_file_cat=$(cat "$SQL_FOLDER$TEMP_INSERT_FILE")
                echo "$temp_insert_file_cat"
                #cat $SQL_FOLDER$TEMP_INSERT_FILE >> $SQL_FOLDER"inserts_records.sql"
  #              echo "psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f $SQL_FOLDER$TEMP_INSERT_FILE"
                ### QUERY insert
                {
                  psql -h $PGSQL_HOST -U $PGSQL_USER -d $PGSQL_DBNAME -p $PGSQL_PORT -f $SQL_FOLDER$TEMP_INSERT_FILE
                } || {
                  echo "[p]SQL ERROR: (INSERT INTO $PGSQL_TABLE_NAME || $PGSQL_TABLE_PARENT_NAME ...)"
                  echo " >> $temp_insert_file_cat"
                }
              else
                echo "Exists property prop_key=\"$prop_key\" prop_value=\"$prop_value\" t:$timestamp"
              fi
#              record_offset=$((record_offset + 1))
#              block=""
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
            echo "Error! on Subprocess [block_inserts] $input:$line_count"
            echo ""
        }
    } || {
      echo "Error! on Process $input"
      echo ""
    }
done
echo "LIST $BACKUP_FOLDER"
ls -tl "$BACKUP_FOLDER"
sudo cp -r "$SPIA_DATA_FOLDER" "$BACKUP_FOLDER"
echo "LIST ${BACKUP_FOLDER}"
ls -tl "${BACKUP_FOLDER}"
sudo rm -Rf ${SPIA_DATA_FOLDER}*