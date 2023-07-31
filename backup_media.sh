#!/bin/bash
# :: Please run only with bash ..
# TASKS:
# 1. read files from logs {folders: (bk/dualcam/ bk/dualcam/media/~)}
# 2. loop per date {format: %Y%m%d} named directories creation {from: %Y%m%01} date
# 3. loop move files to date {format} named directories
# 4. loop zip compression {level: -9} and remove files
# 5. {force: 1} remove date {format} named directories
ROOT="/home/marcel/"
SCRIPT_FILE="${ROOT}scripts/backup_media.sh"
LOCATIONS=("bk/dualcam/" "bk/dualcam/media/~")
if [[ "$1" != "" ]]
then
    {
        IFS=',' read -ra LOCATIONS <<< "$1"
    } || {
        echo "ERROR: invalid LOCATIONS format => $1"
    }
fi
FROM=$(date +"%Y-%m-01")
if [[ "$2" != "" ]]
then
    {
        FROM=$(date +"%Y-%m-%d" -d "$2")
    } || {
        echo "ERROR: invalid FROM format => $2"
    }
fi
FORCE=1
if [[ "$3" != "" ]]
then
    {
        FORCE=$(( $3 ))
    } || {
        echo "ERROR: invalid FORCE format => $3"
    }
fi
LEVEL="-9"
if [[ "$4" != "" ]]
then
    {
        LEVEL="$4"
    } || {
        echo "ERROR: invalid LEVEL format => $4"
    }
fi
TO=$(date +"%Y-%m-%d")
{
    for location in ${LOCATIONS[*]}
    do
        {
            location_dir=$(echo $location | sed "s/\~//g")
            if [[ $location == "$ROOT"* ]]
            then
                cd $location_dir
            else        
                cd $ROOT$location_dir
            fi
            if [[ $location == *"/~" ]]
            then                
                directories=($(find . -maxdepth 1 -mindepth 1 -type d | sed -e "s/.\///g" ))
                for inner_directory in ${directories[*]}
                do 
                    bash $SCRIPT_FILE "$ROOT$location$inner_directory/" "$FROM" "$FORCE" "$LEVEL"
                done
                continue
            fi
            date_from=$FROM
            while [[ $date_from != $TO ]]
            do
                echo "date_from: $date_from"
                {
                    directory=$(echo $date_from | sed "s/-//g")
                    {
                        mkdir "$directory"; 
                    } || {
                        echo "Could not create directory $directory"
                    }
                    {
                        mv *${date_from}*".h265" "${directory}/";
                        mv *${date_from}*".mp4" "${directory}/";
                    } || { 
                        echo "could not move video files to $directory"
                    }
                    {
                        mv *${date_from}*".jpeg" "${directory}/"; 
                        # mv *${directory}*".log" "${directory}/"; 
                    } || { 
                        echo "could not move images to $directory"
                    }
                    {
                        zip $LEVEL -r "${directory}.zip" "${directory}/"
                    } || { 
                        echo "could not compress files on $directory"
                    }
                    if (( 1 <= $FORCE ))
                    then
                        rm -Rf "${directory}/"*
                    fi
                } || { 
                    echo "ERROR: Failed to backup ${directory}"
                }
                {
                    date_from=$(date +"%s" -d "$date_from") 
                    date_from=$(( $date_from + 86400 ))
                    date_from=$(date +"%Y-%m-%d" -d "@$date_from") 
                    echo "date_from changed: $date_from"
                } || {
                    echo "ERROR: Failed to update date_from: $date_from"
                    break
                }
            done
        } || {
            echo "ERROR: location not found: $location"
        }
    done
} || {
    echo "ERROR: could not execute backup commands on :"${LOCATIONS[*]}
}