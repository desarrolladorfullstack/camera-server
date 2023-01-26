#!/bin/bash
RUN_DIR="/opt"
PROJECT_NAME="camera-server"
EXEC_FILE="index.js"
RUNNER="node"
ARGS="-p 80"
LOGS_DIR="/var/logs"
LOG_FILE_NAME="spia-camera-server"
# with error log
$RUNNER $RUN_DIR"/"$PROJECT_NAME"/"$EXEC_FILE $ARGS 2> $LOGS_DIR"/"$LOG_FILE_NAME".errors" >> $LOGS_DIR"/"$LOG_FILE_NAME".log" &
# only log
#$RUNNER $RUN_DIR"/"$PROJECT_NAME"/"$EXEC_FILE 2> /dev/null > $LOGS_DIR"/"$LOG_FILE_NAME".log" &