#!/bin/bash
# python should be run from shell with activated environment (if virtual env is used)
# parse args
while getopts d: flag
do
    case "${flag}" in
        d) run_dir=${OPTARG};;
        *) echo "incorrect flag" && exit 1;;
    esac
done
# check args
if [ -z "$run_dir" ]
then
      echo "Error! Specify RUN directory with -d flag."
      exit 1
fi
# init vars
colmap_dir="<PATH TO COLMAP BINARY>"
openmvs_dir="<PATH TO OPENMVS BINARY>"

mkdir "runs/$run_dir"
path_to_workspace="$PWD/$run_dir"
# run SfM - MVS pipeline
./run_video_final_ini.sh -c "$colmap_dir" -o "$openmvs_dir" -d "$path_to_workspace"