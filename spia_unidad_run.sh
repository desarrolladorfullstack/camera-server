#!/bin/bash
RUN_DIR="/opt"
PROJECT_NAME="spia-view-backend"
EXEC_FILE="index.js"
RUNNER="node"
LOGS_DIR="/home/node/logs/11"
LOG_FILE_NAME="spia-view-unidad"
# with error log
scp -i$RUNNER $RUN_DIR"/"$PROJECT_NAME"/"$EXEC_FILE 2> $LOGS_DIR"/"$LOG_FILE_NAME".errors" > $LOGS_DIR"/"$LOG_FILE_NAME".log" &
# only log
$RUNNER $RUN_DIR"/"$PROJECT_NAME"/"$EXEC_FILE 2> /dev/null > $LOGS_DIR"/"$LOG_FILE_NAME".log" &
