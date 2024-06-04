#!/bin/bash

# run as:  ./run_sfm_mvs.sh -c <PATH TO COLMAP BINARY> -o <PATH TO OpenMVS FOLDER> -d <directory>

# pass params: 
#   ($1) deep_run (0 or 1)
#       run full COLMAP SfM pipeline or only map result from the deep run
#   ($2) only_mvs (0 or 1)
#       run full COLMAP SfM pipeline or only the part that is necessary for MVS
function sfm_pipeline () {
    # args naming
    local deep_run="$1"
    local only_mvs="$2"
    # time vars init 
    local time_start=$(date +%s)
    local time_feature_end=0
    local time_match_end=0
    local time_mapper_end=0
    local time_end=0
    # SfM pipeline start
    if [ "$only_mvs" -eq 0 ]
    then
        if [ "$deep_run" -eq 0 ]
        then
            $colmap_dir feature_extractor \
            --project_path "$path_to_config/${colmap_config_subname}feature-extraction.ini"
            echo "Passed feature"
            time_feature_end=$(date +%s)
            $colmap_dir sequential_matcher \
            --project_path "$path_to_config/${colmap_config_subname}feature-matching.ini"
            echo "Passed matcher"
            time_match_end=$(date +%s)
        fi
        if [ ! -d "sparse" ]
        then
            mkdir "sparse"
        fi
        # --Mapper.multiple_models 1 is beneficial for performance but may produce several sparse models
        # --Mapper.num_threads -1 can be (and will be) undeterministic, can be fixed with 1.
        $colmap_dir mapper \
        --project_path "$path_to_config/${colmap_config_subname}mapper.ini" \
        --output_path "sparse"
        echo "Passed mapper"
        time_mapper_end=$(date +%s)
    fi
    # data preparation for MVS stage (OpenMVS)
    if [ ! -d "dense" ]
    then
        mkdir "dense"
    fi
    $colmap_dir image_undistorter \
    --project_path "$path_to_config/${colmap_config_subname}image-undistorter.ini" \
    --input_path "sparse/0" \
    --output_path "dense" \
    --output_type COLMAP
    echo "Passed image_undistorter"
    $colmap_dir model_converter \
    --project_path "$path_to_config/${colmap_config_subname}model-converter.ini" \
    --input_path "dense/sparse" \
    --output_path "dense/sparse"  \
    --output_type TXT
    echo "Passed model_converter"
    time_end=$(date +%s)
    # statistics
    local runtime_all=$((time_end-time_start))
    local runtime_feature=$((time_feature_end-time_start))
    local runtime_match=$((time_match_end-time_feature_end))
    local runtime_mapper=$((time_mapper_end-time_match_end))
    local runtime_util=$((runtime_all-runtime_feature-runtime_match-runtime_mapper))
    if [ "$deep_run" -eq 0 ]
    then
        echo -e "SfM pipeline:\n\ttotal time: $runtime_all\n\tfeature extraction time: $runtime_feature\n\tmatching time: $runtime_match\n\tmapping time: $runtime_mapper\n\tutil time: $runtime_util\n" >> "$file_log_time"
    else
        echo -e "SfM pipeline:\n\ttotal time: $runtime_all\n\tfeature extraction time: $runtime_feature\n\tmatching time: $runtime_match\n\tmapping time: $runtime_mapper\n\tutil time: $runtime_util\n" >> "$file_log_time"
    fi

    return 0
}


# pass params: 
#   ($1) make_mesh (0 or 1)
#       process point cloud to mesh or not (0 for early exit)
#   ($2) verbosity (0-4)
#       logging level
#   ($3) use_gpu (-1 or -2 for GPU and CPU respectively)
#       use GPU or not
#   ($?) mask_path (path)
#       path to folder with image masks (image001.jpg -> image001.mask.png)
function mvs_pipeline () {
    # args naming
    local make_mesh="$1"
    #local mask_path="$2"
    #local quality_mode="$3"
    local verbosity="$2"
    local use_gpu="$3"
    # time vars init 
    local time_start=$(date +%s)
    local time_densify_start=0
    local time_densify_end=0
    local time_reconstruct_end=0
    local time_refine_end=0
    local time_texture_end=0
    local time_end=0
    # MVS pipeline start
    $openmvs_dir/InterfaceCOLMAP \
    --working-folder "$path_to_project/dense" \
    --config-file "$path_to_config/${mvs_config_subname}interface.cfg" \
    --verbosity "$verbosity"
    echo "Passed InterfaceCOLMAP"
    time_densify_start=$(date +%s)
    $openmvs_dir/DensifyPointCloud \
    --working-folder "$path_to_project/mvs" \
    --config-file "$path_to_config/${mvs_config_subname}densify.cfg" \
    --verbosity "$verbosity" \
    --cuda-device "$use_gpu"
    echo "Passed DensifyPointCloud"
    time_densify_end=$(date +%s)
    if [ "$make_mesh" -eq 0 ]
    then
        return 0
    fi
    $openmvs_dir/ReconstructMesh \
    --working-folder "$path_to_project/mvs" \
    --config-file "$path_to_config/${mvs_config_subname}reconstruct.cfg" \
    --verbosity "$verbosity" \
    --cuda-device "$use_gpu"
    echo "Passed ReconstructMesh"
    time_reconstruct_end=$(date +%s)
    $openmvs_dir/RefineMesh \
    --working-folder "$path_to_project/mvs" \
    --config-file "$path_to_config/${mvs_config_subname}refine.cfg" \
    --verbosity "$verbosity" \
    --cuda-device "$use_gpu"
    echo "Passed RefineMesh"
    time_refine_end=$(date +%s)
    $openmvs_dir/TextureMesh \
    --working-folder "$path_to_project/mvs/" \
    --config-file "$path_to_config/${mvs_config_subname}texture.cfg" \
    --verbosity "$verbosity" \
    --export-type glb \
    --cuda-device "$use_gpu"
    echo "Passed TextureMesh"
    time_texture_end=$(date +%s)
    time_end=$(date +%s)
    # statistics
    local runtime_all=$((time_end-time_start))
    local runtime_densify=$((time_densify_end-time_densify_start))
    local runtime_reconstruct=$((time_reconstruct_end-time_densify_end))
    local runtime_refine=$((time_refine_end-time_reconstruct_end))
    local runtime_texture=$((time_texture_end-time_refine_end))
    local runtime_util=$((runtime_all-runtime_densify-runtime_reconstruct-runtime_refine-runtime_texture))
    echo -e "MVS pipeline:\n\ttotal time: $runtime_all\n\tdensify time: $runtime_densify\n\treconstruct time: $runtime_reconstruct\n\trefine time: $runtime_refine\n\ttexture time: $runtime_texture\n\tutil time: $runtime_util\n" >> "$file_log_time"

    return 0
}

# init default vars
deep_run=0
mvs_make_mesh=0
project_name="project"
colmap_config_subname="COLMAP-3.9.1-config-"
colmap_only_mvs=0
# parse args
while getopts c:o:d:t flag
do
    case "${flag}" in
        c) colmap_dir=${OPTARG};;
        o) openmvs_dir=${OPTARG};;
        d) workspace_dir=${OPTARG};;
        t) colmap_only_mvs=1;;
        *) echo "incorrect flag" && exit 1;;
    esac
done
# check args
if [ -z "$colmap_dir" ] || [ -z "$openmvs_dir" ] || [ -z "$workspace_dir" ]
then
      echo "Error! Specify COLMAP and OpenMVS bin paths with -c and -o flags respectively. 
      Also don't forget to provide workspace directory with corresponding -d flag"
      exit 1
fi
WHITE="\033[1;37m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
file_log_time="$workspace_dir/$project_name/log_time.txt"
# mvs config file options
path_to_project="$workspace_dir/$project_name"
path_to_config="$path_to_project/configs"
mvs_config_subname="OpenMVS-2.3.0-config-"
quality_mode="low"
mvs_verbosity=2
mvs_use_gpu=-2
general_config_subname="config-"
config_counter=0
echo "TEST: $workspace_dir"
echo "TEST: $path_to_project"
while IFS= read -r line; do
    # trim leading and trailing whitespace
    echo "GENERAL CONFIG line $config_counter: $line"
    config_counter=$((config_counter+1))
    temp_var=$(echo $line | xargs)
    if [ "$config_counter" -eq 1 ];
    then
        deep_run=$temp_var
    elif [ "$config_counter" -eq 2 ];
    then
        quality_mode=$temp_var
    elif [ "$config_counter" -eq 3 ];
    then
        mvs_make_mesh=$temp_var
    elif [ "$config_counter" -eq 4 ]; 
    then
        mvs_verbosity=$temp_var
    elif [ "$config_counter" -eq 5 ]; 
    then
        mvs_use_gpu=$temp_var
    fi
done < "$path_to_config/${general_config_subname}RUNTIME.txt"
if [ -d "$workspace_dir" ]; then
    echo "CURRENT DIRECTORY: $dir"
    cd "$workspace_dir" || (echo -e "$RED unable to cd to $workspace_dir" && exit 1)
    cd "$project_name" || (echo -e "$RED unable to cd to $workspace_dir/$project_name" && exit 1)
    # main code
    echo -e "$YELLOW Reconstruction started"
    echo -e "$WHITE"
    echo "$workspace_dir/$project_name"
    time_start=$(date +%s)
    deep_use_gpu=0
    if [ "$mvs_use_gpu" -eq -1 ]
    then
        deep_use_gpu=1
    fi
    echo "$deep_use_gpu"
    if [ "$deep_run" -eq 1 ] && [ "$colmap_only_mvs" -eq 0 ];
    then
        python ../../../utils/deep-sfm/deep_sfm_driver.py "$workspace_dir" "$quality_mode" "$deep_use_gpu"
    fi
    sfm_pipeline "$deep_run" "$colmap_only_mvs"
    time_sfm_end=$(date +%s)
    if [ ! -d "mvs" ]
    then
        mkdir "mvs"
    fi
    cd "mvs" || (echo -e "$RED unable to cd to mvs/" && exit 1)
    mvs_mask_path=""
    mvs_pipeline "$mvs_make_mesh" "$mvs_verbosity" "$mvs_use_gpu"
    cd "../../../.." || (echo -e "$RED unable to cd to starting directory (../../../..)" && exit 1)
    time_end=$(date +%s)
    # process info
    runtime_all=$((time_end-time_start))
    runtime_sfm=$((time_sfm_end-time_start))
    runtime_mvs=$((time_end-time_sfm_end))
    echo -e "$YELLOW Reconstruction: deep_run=$deep_run, mvs_make_mesh=$mvs_make_mesh, mvs_verbosity=$mvs_verbosity, mvs_use_gpu=$mvs_use_gpu"
    echo -e "$YELLOW      Elapsed SfM Time: $runtime_sfm seconds" 
    echo -e "$YELLOW      Elapsed MVS Time: $runtime_mvs seconds"
    echo -e "$YELLOW      Elapsed Total Time: $runtime_all seconds"
    echo -e "$WHITE"
    echo "Reconstruction: deep_run=$deep_run, mvs_make_mesh=$mvs_make_mesh, mvs_verbosity=$mvs_verbosity, mvs_use_gpu=$mvs_use_gpu" >> "$file_log_time"
    echo "      Elapsed SfM Time: $runtime_sfm seconds" >> "$file_log_time"
    echo "      Elapsed MVS Time: $runtime_mvs seconds" >> "$file_log_time"
    echo "      Elapsed Total Time: $runtime_all seconds" >> "$file_log_time"
    # convert resulting model (include texture)
    path_to_model="$workspace_dir/$project_name/mvs/model_dense.ply"
    path_to_converted_model="$workspace_dir/$project_name/mvs/model_final.glb"
    mode="pointcloud"
    if [ "$mvs_make_mesh" -eq 1 ]
    then
        path_to_model="$workspace_dir/$project_name/mvs/model.glb"
        mode="mesh"
    fi
    echo -e "$YELLOW CONVERTING MODEL.."
    python $workspace_dir/../../utils/model-convert/model_convert_driver.py "$path_to_model" "$path_to_converted_model" "$mode"
else
    echo -e "$RED directory $workspace_dir doesn't exist" && exit 1
fi
echo -e "$GREEN SUCCESS"