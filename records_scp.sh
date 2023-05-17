#!/bin/bash
# :: Please run only with bash ..
# TASKS:
# 1. docker copy media files
# 2. loop media file contents
# 2.1 sql insert on datasource (records, pgsql)
# 2.2 remove docker media files
# 3. remove copied media files on host
HOST_FOLDER='/home/ubuntu/'
if [[ "$4" != "" ]]
then
    HOST_FOLDER=$4
fi
SCRIPTS_FOLDER=""
if [[ "$5" != "" ]]
then
    SCRIPTS_FOLDER=$5
fi
HOST_MEDIA_FOLDER=$HOST_FOLDER'media/'
DOWNLOADS_FOLDER="downloads/"
SCRIPT_NAME=$SCRIPTS_FOLDER"records_camera.sh"
if [[ "$3" != "" ]]
then
    HOST_MEDIA_FOLDER=$3
fi
DOCKER_NAME='spia-dualcam'
if [[ "$1" != "" ]]
then
    DOCKER_NAME=$1
fi
DOCKER_MEDIA_FOLDER='/home/node/media/'
if [[ "$2" != "" ]]
then
    DOCKER_MEDIA_FOLDER=$2
fi
# DOCKER_MEDIA_FOLDER=$DOWNLOADS_FOLDER
# BEGIN: docker cp downloads script
# sudo docker cp $DOCKER_NAME":/"$DOWNLOADS_FOLDER $HOST_FOLDER
# END: docker cp downloads script
echo "=== copying from Docker ==="
# date
echo "> Docker Media Files ($DOCKER_MEDIA_FOLDER):"
docker exec "$DOCKER_NAME" bash -c "ls -tl $DOCKER_MEDIA_FOLDER"
docker cp "$DOCKER_NAME:$DOCKER_MEDIA_FOLDER." "$HOST_MEDIA_FOLDER"
# &
# sudo docker cp $DOCKER_NAME":"$DOCKER_MEDIA_FOLDER$DOWNLOADS_FOLDER $HOST_FOLDER
#echo "${DOCKER_NAME} , ${DOCKER_MEDIA_FOLDER} , ${HOST_MEDIA_FOLDER}"
echo "> Media Files ($HOST_MEDIA_FOLDER):"
# sleep 5
ls -tl "$HOST_MEDIA_FOLDER"
# date
echo "=== executing script ==="
bash "$HOST_FOLDER$SCRIPT_NAME" "$HOST_MEDIA_FOLDER" "$HOST_FOLDER" "${HOST_FOLDER}bk/" 2>> $HOST_FOLDER"logs/records_flush_"$(date "+%Y-%m-%d_%H")".error" >> $HOST_FOLDER"logs/records_flush_"$(date "+%Y-%m-%d_%H")".log"
#sleep 3
# sudo docker exec $DOCKER_NAME bash -c "rm -Rf ${DOCKER_MEDIA_FOLDER}*"
# sudo rm -Rf ${HOST_MEDIA_FOLDER}*