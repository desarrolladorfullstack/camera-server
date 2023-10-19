#!/bin/bash
home_dir="/home/marcel/"
project_dir="projects/spia-gps"
bot_filename="manage.py"
log_filename="spia_gps.log"
venv_name="spiaenv"
args=("runserver" "localhost:6800")
ls -l
source $home_dir$project_dir"/${venv_name}/bin/activate"
cd $home_dir$project_dir
{
  python3 -V
  python3 $bot_filename ${args[*]} 2> $log_filename > $log_filename &
} || {
  $home_dir$project_dir"/${venv_name}/bin/python3" $bot_filename ${args[*]} 2> $log_filename > $log_filename &
}