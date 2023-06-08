#!/bin/bash
HOST_FOLDER="/home/marcel/"
BK_FOLDER="bk/dualcam/data"
DOCKER_CONTAINER="spia-dualcam_v2"
DOCKER_FOLDER="/home/node/data/"
bash /home/marcel/scripts/spia_data_scp.sh "$DOCKER_CONTAINER" "$DOCKER_FOLDER" "${HOST_FOLDER}spia/" "$HOST_FOLDER" "scripts/" 2>> $HOST_FOLDER$BK_FOLDER"/spia_data_cron_"$(date "+%Y-%m-%d")".error" >> $HOST_FOLDER$BK_FOLDER"/spia_data_cron_"$(date "+%Y-%m-%d")".log"