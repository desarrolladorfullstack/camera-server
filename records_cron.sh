#!/bin/bash
HOST_FOLDER="/home/marcel/"
DOCKER_CONTAINER="spia-dualcam_files_v2"
bash /home/marcel/scripts/records_scp.sh "$DOCKER_CONTAINER" "/downloads/" "${HOST_FOLDER}media/" "$HOST_FOLDER" "scripts/" 2>> $HOST_FOLDER"bk/records_cron_"$(date "+%Y-%m-%d")".error" >> $HOST_FOLDER"bk/records_cron_"$(date "+%Y-%m-%d")".log"