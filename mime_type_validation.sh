dir="/c/Projects/Node/media/"
if [[ "$1" != "" ]]
then
    dir=$1
fi
move_to=$dir"videos/"
if [[ "$3" != "" ]]
then
    move_to=$3
fi
#move_to=$dir"images/"
list_files=($(ls -t $dir | grep "file_raw_"))
declare -a list_match
match="application/octet-stream"
if [[ "$2" != "" ]]
then
    match=$2
fi
#match="image/jpeg" 
for file in ${list_files[*]}
do 
    mime_type=($(file --mime-type $dir$file))
    if [[ ${mime_type[-1]} == "$match" ]]
    then
        value_match=$dir$file":"${mime_type[-1]}
        list_match+=(\"$dir$file\")
        if [[ ! -d "$dir$move_to" ]]
        then 
            echo "directory $dir$move_to created ..."
            mkdir "$dir$move_to"
        fi
        if [[ $match == "image/jpeg" ]]
        then
            mv $dir$file $dir$move_to$file".jpg"
        else
            mv $dir$file $move_to
        fi
    else
        echo "No aplica..."
        file --mime-type $dir$file
    fi
done
# echo "FILES MATCH: "${list_match[@]}