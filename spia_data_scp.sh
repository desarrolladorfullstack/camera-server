#!/bin/bash
# :: Please run only with bash ..
# TASKS:
# 1. docker copy data files
# 2. loop data file contents
# 2.1 sql insert on datasource (records, pgsql)
# 2.2 remove docker data files
# 3. remove copied data files on host
HOST_FOLDER='/home/ubuntu/'
BK_FOLDER="bk/dualcam/data/"
if [[ "$4" != "" ]]
then
    HOST_FOLDER=$4
fi
SCRIPTS_FOLDER=""
if [[ "$5" != "" ]]
then
    SCRIPTS_FOLDER=$5
fi
HOST_DATA_FOLDER=$HOST_FOLDER'spia/'
DOWNLOADS_FOLDER="downloads/"
SCRIPT_NAME=$SCRIPTS_FOLDER"spia_data_tracker.sh"
if [[ "$3" != "" ]]
then
    HOST_DATA_FOLDER=$3
fi
DOCKER_NAME='spia-dualcam'
if [[ "$1" != "" ]]
then
    DOCKER_NAME=$1
fi
DOCKER_DATA_FOLDER='/home/node/data/'
if [[ "$2" != "" ]]
then
    DOCKER_DATA_FOLDER=$2
fi
# DOCKER_DATA_FOLDER=$DOWNLOADS_FOLDER
# BEGIN: docker cp downloads script
# sudo docker cp $DOCKER_NAME":/"$DOWNLOADS_FOLDER $HOST_FOLDER
# END: docker cp downloads script
# date
echo "> Docker Spia Data Files ($DOCKER_DATA_FOLDER):"
total_docker_data=$(docker exec "$DOCKER_NAME" bash -c "find $DOCKER_DATA_FOLDER -type f -regex '.*\(.spia\)$'")
echo "$total_docker_data"
if [[ "$total_docker_data" != "total 0" ]] && [[ "$total_docker_data" != "" ]]
then
  echo "=== copying from Docker ==="
  docker cp "$DOCKER_NAME:$DOCKER_DATA_FOLDER." "$HOST_DATA_FOLDER"
fi
# &
# sudo docker cp $DOCKER_NAME":"$DOCKER_DATA_FOLDER$DOWNLOADS_FOLDER $HOST_FOLDER
#echo "${DOCKER_NAME} , ${DOCKER_DATA_FOLDER} , ${HOST_DATA_FOLDER}"
echo "> Spia Data Files ($HOST_DATA_FOLDER):"
# sleep 5
total_host_data=$(find "$HOST_DATA_FOLDER" -type f)
echo "$total_host_data"
# date
if [[ "$total_host_data" != "total 0" ]] && [[ "$total_host_data" != "" ]]
then
  echo "=== executing script ==="
  bash "$HOST_FOLDER$SCRIPT_NAME" "$HOST_DATA_FOLDER" "$HOST_FOLDER" "${HOST_FOLDER}${BK_FOLDER}" 2>> $HOST_FOLDER"logs/spia_data_flush_"$(date "+%Y-%m-%d_%H")".error" >> $HOST_FOLDER"logs/spia_data_flush_"$(date "+%Y-%m-%d_%H")".log"
fi
#sleep 3
if [[ "$total_docker_data" != "total 0" ]] && [[ "$total_docker_data" != "" ]]
then
  echo "=== RM: Docker Spia Data Files ==="
  sudo docker exec $DOCKER_NAME bash -c "rm -Rf ${DOCKER_DATA_FOLDER}*"
fi
# sudo rm -Rf ${HOST_DATA_FOLDER}*