dir="/c/Projects/Node/media/"
if [[ "$1" != "" ]]
then
    dir=$1
fi
FILE_SEARCH='file_raw_'
if [[ "$2" != "" ]]
then
    FILE_SEARCH=$2
fi
mv_extension='h265'
if [[ "$3" != "" ]]
then
    mv_extension=$3
fi
fps_value=25
if [[ "$4" != "" ]]
then
    fps_value=$4
fi
cp_extension='mp4'
if [[ "$5" != "" ]]
then
    cp_extension=$5
fi
# echo "ls -t $dir | grep \"$FILE_SEARCH\""
list_files=($(ls -t $dir | grep "$FILE_SEARCH"))
declare -a list_match
match="application/octet-stream"
for file in ${list_files[*]}
do 
    mime_type=($(file --mime-type $dir$file))
    if [[ ${mime_type[-1]} == "$match" ]]
    then
        value_match=$dir$file":"${mime_type[-1]}
        list_match+=(\"$dir$file\")
        if [[ "$dir$file" == *".$mv_extension" ]]
        then
            echo "compiling ... "$dir$file             
            ffmpeg -r $fps_value -i $dir$file -c:a copy -c:v libx264 $dir$file.$cp_extension
        else
            echo "converting ... "$dir$file
            mv $dir$file $dir$file.$mv_extension
            ffmpeg -r $fps_value -i $dir$file.$mv_extension -c:a copy -c:v libx264 $dir$file.$cp_extension
        fi
    fi
done
# echo "FILES MATCH: "${list_match[@]}