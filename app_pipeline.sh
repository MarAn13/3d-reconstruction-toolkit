#!/bin/bash
# python should be run from shell with activated environment (if virtual env is used)
# parse args
while getopts d: flag
do
    case "${flag}" in
        d) run_dir_name=${OPTARG};;
        *) echo "incorrect flag" && exit 1;;
    esac
done
# check args
if [ -z "$run_dir_name" ]
then
      echo "Error! Specify RUN directory name with -d flag."
      exit 1
fi
# init vars
#colmap_dir="<PATH TO COLMAP BINARY>"
#openmvs_dir="<PATH TO OPENMVS FOLDER>"
colmap_dir="C:\Users\marem\dev\projects\unn\cw\COLMAP-3.9.1-windows-cuda\COLMAP.bat"
openmvs_dir="C:\Users\marem\dev\projects\unn\cw\OpenMVS-2.3.0-windows"

mkdir "runs/$run_dir_name"
# run data processing
python run_data_processing.py "$run_dir_name"
# run SfM - MVS pipeline
path_to_workspace="$PWD/runs/$run_dir_name"
./run_sfm_mvs.sh -c "$colmap_dir" -o "$openmvs_dir" -d "$path_to_workspace"