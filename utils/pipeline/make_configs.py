import configparser
import re


#############################################################
#       COLMAP CONFIGS                                      #
#                                                           #
#############################################################
# change based on data type mode (video)
def adapt_config_to_data_type(config, mode):
    if mode == "video":
        config["Mapper"]["init_min_tri_angle"] = str(
            int(int(config["Mapper"]["init_min_tri_angle"]) // 2)
        )
        config["Mapper"]["ba_global_images_ratio"] = "1.4"
        config["Mapper"]["ba_global_points_ratio"] = "1.4"
        config["Mapper"]["min_focal_length_ratio"] = "0.1"
        config["Mapper"]["max_focal_length_ratio"] = "10"
        # std::numeric_limits<double>::max()
        config["Mapper"]["max_extra_param"] = "1.79769e+308"
    return config


# change based on quality mode
def adapt_config_to_quality(config, mode):
    """
    config - config
    mode - low or mid or high
    """
    if mode == "low":
        config["SiftExtraction"]["max_image_size"] = "1000"
        config["SiftExtraction"]["max_num_features"] = "2048"
        config["SequentialMatching"]["loop_detection_num_images"] = str(
            int(int(config["SequentialMatching"]["loop_detection_num_images"]) // 2)
        )
        config["Mapper"]["ba_local_max_num_iterations"] = str(
            int(int(config["Mapper"]["ba_local_max_num_iterations"]) // 2)
        )
        config["Mapper"]["ba_global_max_num_iterations"] = str(
            int(int(config["Mapper"]["ba_global_max_num_iterations"]) // 2)
        )
        config["Mapper"]["ba_global_images_ratio"] = str(
            float(config["Mapper"]["ba_global_images_ratio"]) * 1.2
        )
        config["Mapper"]["ba_global_points_ratio"] = str(
            float(config["Mapper"]["ba_global_points_ratio"]) * 1.2
        )
        config["Mapper"]["ba_global_max_refinements"] = "2"
    elif mode == "mid":
        config["SiftExtraction"]["max_image_size"] = "1600"
        config["SiftExtraction"]["max_num_features"] = "4096"
        config["SequentialMatching"]["loop_detection_num_images"] = str(
            int(int(config["SequentialMatching"]["loop_detection_num_images"]) // 1.5)
        )
        config["Mapper"]["ba_local_max_num_iterations"] = str(
            int(int(config["Mapper"]["ba_local_max_num_iterations"]) // 1.5)
        )
        config["Mapper"]["ba_global_max_num_iterations"] = str(
            int(int(config["Mapper"]["ba_global_max_num_iterations"]) // 1.5)
        )
        config["Mapper"]["ba_global_images_ratio"] = str(
            float(config["Mapper"]["ba_global_images_ratio"]) * 1.1
        )
        config["Mapper"]["ba_global_points_ratio"] = str(
            float(config["Mapper"]["ba_global_points_ratio"]) * 1.1
        )
        config["Mapper"]["ba_global_max_refinements"] = "2"
    elif mode == "high":
        config["SiftExtraction"]["estimate_affine_shape"] = "true"
        config["SiftExtraction"]["domain_size_pooling"] = "true"
        config["SiftMatching"]["guided_matching"] = "true"
        config["Mapper"]["ba_local_max_num_iterations"] = "40"
        config["Mapper"]["ba_local_max_refinements"] = "3"
        config["Mapper"]["ba_global_max_num_iterations"] = "100"
    return config


# change based on util vars (shared_camera, use_gpu)
def adapt_to_util(config, shared_camera, use_gpu):
    config["ImageReader"]["single_camera"] = str(shared_camera == True).lower()
    config["SiftExtraction"]["use_gpu"] = str(use_gpu == True).lower()
    config["SiftMatching"]["use_gpu"] = str(use_gpu == True).lower()
    return config


# change based on runtime vars (images, database, masks)
def adapt_to_runtime(config, path_to_images, path_to_database, path_to_masks):
    config["RUNTIME"]["random_seed"] = "42"
    config["RUNTIME"]["log_level"] = "0"
    config["RUNTIME"]["image_path"] = path_to_images
    config["RUNTIME"]["database_path"] = path_to_database
    config["ImageReader"]["mask_path"] = path_to_masks
    config["SequentialMatching"]["vocab_tree_path"] = (
        "vocab_tree_flickr100K_words32K.bin"
    )
    return config


# save config file in .ini or .cfg format
def save_config(config, path_to_file):
    # save file in configparser format
    with open(path_to_file, "w") as configfile:
        config.write(configfile)
    # remove whitespaces and blank lines
    file = open(path_to_file, "r")
    data = file.read()
    file.close()
    # remove whitespaces
    data = data.replace(" ", "")
    # remove blank lines
    data = data.split("\n")
    data = list(filter(lambda x: not re.match(r"^\s*$", x), data))
    # remove ['RUNTIME'] section
    data = data[1:]
    data = "\n".join(data)
    data += "\n"
    with open(path_to_file, "w") as file:
        file.write(data)


# adapt to specific pipeline (e.g. feature extraction, feature matching, ...)
def colmap_adapt_config(config, params):
    config_pipelines = [
        "feature-extraction",
        "feature-matching",
        "mapper",
        "image-undistorter",
        "model-converter",
    ]
    config_sections = [
        ["RUNTIME", "ImageReader", "SiftExtraction"],
        ["RUNTIME", "SiftMatching", "TwoViewGeometry", "SequentialMatching"],
        ["RUNTIME", "Mapper"],
        ["RUNTIME"],
        ["RUNTIME"],
    ]
    for pipeline, sections in zip(config_pipelines, config_sections):
        pipeline_config = configparser.ConfigParser()
        for section in sections:
            pipeline_config[section] = {}
            for key, val in config[section].items():
                pipeline_config[section][key] = val
        # exceptions
        if pipeline == "feature-matching":
            del pipeline_config["RUNTIME"]["image_path"]
        elif pipeline == "mapper":
            pipeline_config["RUNTIME"]["output_path"] = "sparse"
        elif pipeline == "image-undistorter":
            pipeline_config["RUNTIME"]["input_path"] = "sparse/0"
            pipeline_config["RUNTIME"]["output_path"] = "dense"
            pipeline_config["RUNTIME"]["output_type"] = "COLMAP"
            del pipeline_config["RUNTIME"]["database_path"]
        elif pipeline == "model-converter":
            pipeline_config["RUNTIME"]["input_path"] = "dense/sparse"
            pipeline_config["RUNTIME"]["output_path"] = "dense/sparse"
            pipeline_config["RUNTIME"]["output_type"] = "TXT"
            del pipeline_config["RUNTIME"]["database_path"]
            del pipeline_config["RUNTIME"]["image_path"]
        save_config(
            pipeline_config,
            params["path_to_config"]
            + "/"
            + params["config_subname"]
            + pipeline
            + ".ini",
        )


def colmap_change_config(path_to_default_config, params):
    config = configparser.ConfigParser()
    config.read(path_to_default_config)
    config = adapt_config_to_data_type(config, params["data_mode"])
    config = adapt_config_to_quality(config, params["quality_mode"])
    config = adapt_to_util(config, params["shared_camera"], params["use_gpu"])
    config = adapt_to_runtime(
        config,
        params["path_to_images"],
        params["path_to_database"],
        params["path_to_masks"],
    )
    colmap_adapt_config(config, params)


def make_project_info(path_to_project, params):
    status_mask = None
    if len(params["path_to_masks"]) != 0:
        status_mask = "segment"
    if params["shared_camera"]:
        status_shared_camera = "shared"
    else:
        status_shared_camera = "notshared"
    if params["deep_run"]:
        status_deep_run = "deep"
    else:
        status_deep_run = "notdeep"
    if params["use_gpu"]:
        status_use_gpu = "gpu"
    else:
        status_use_gpu = "cpu"
    project_info = f"project-{params['data_mode']}-{params['quality_mode']}-{status_mask}-{status_shared_camera}-{status_use_gpu}-{status_deep_run}"
    project_info_filename = "PROJECT-INFO.txt"
    with open(path_to_project + "/" + project_info_filename, "w") as file:
        file.write(project_info)


#############################################################
#       OpenMVS CONFIGS                                     #
#                                                           #
#############################################################


# change based on quality mode
def openmvs_adapt_config_to_quality(config, mode):
    """
    config - config
    mode - low or mid or high
    """
    config["interface"] = {}
    config["densify"] = {}
    config["reconstruct"] = {}
    config["refine"] = {}
    config["texture"] = {}
    if mode == "low":
        config["densify"]["resolution-level"] = "2"
        config["densify"]["max-resolution"] = "512"
        config["densify"]["sub-resolution-levels"] = "0"
        config["densify"]["number-views"] = "6"
        config["reconstruct"]["min-point-distance"] = "6"
        config["refine"]["resolution-level"] = "2"
        config["refine"]["max-views"] = "6"
        config["refine"]["scales"] = "2"
        config["texture"]["resolution-level"] = "2"
    elif mode == "mid":
        config["densify"]["resolution-level"] = "1"
        config["densify"]["max-resolution"] = "1024"
        config["densify"]["sub-resolution-levels"] = "1"
        config["densify"]["number-views"] = "8"
        config["reconstruct"]["min-point-distance"] = "4"
        config["refine"]["resolution-level"] = "1"
        config["refine"]["max-views"] = "8"
        config["refine"]["scales"] = "2"
        config["texture"]["resolution-level"] = "1"
    elif mode == "high":
        config["densify"]["resolution-level"] = "0"
        config["densify"]["max-resolution"] = "2560"
        config["densify"]["sub-resolution-levels"] = "2"
        config["densify"]["number-views"] = "10"
        config["reconstruct"]["min-point-distance"] = "2.5"
        config["refine"]["resolution-level"] = "0"
        config["refine"]["max-views"] = "10"
        config["refine"]["scales"] = "2"
        config["texture"]["resolution-level"] = "0"
    return config


def openmvs_adapt_to_runtime(config, path_to_project):
    config["interface"]["input-file"] = f"{path_to_project}/dense"
    config["interface"]["output-file"] = f"{path_to_project}/mvs/model_colmap.mvs"
    config["densify"]["input-file"] = f"{path_to_project}/mvs/model_colmap.mvs"
    config["densify"]["output-file"] = f"{path_to_project}/mvs/model_dense.mvs"
    # TO-DO: ADD MASKS
    config["densify"]["mask-path"] = ""
    config["densify"]["remove-dmaps"] = "1"
    config["reconstruct"]["input-file"] = f"{path_to_project}/mvs/model_dense.mvs"
    config["reconstruct"]["output-file"] = f"{path_to_project}/mvs/model_dense_mesh.mvs"
    config["refine"]["input-file"] = f"{path_to_project}/mvs/model_dense.mvs"
    config["refine"]["mesh-file"] = f"{path_to_project}/mvs/model_dense_mesh.ply"
    config["refine"]["output-file"] = (
        f"{path_to_project}/mvs/model_dense_mesh_refine.mvs"
    )
    config["texture"]["input-file"] = f"{path_to_project}/mvs/model_dense.mvs"
    config["texture"]["mesh-file"] = (
        f"{path_to_project}/mvs/model_dense_mesh_refine.ply"
    )
    config["texture"]["output-file"] = f"{path_to_project}/mvs/model.obj"
    return config


# adapt to specific pipeline (e.g. interface, densify, ...)
def openmvs_adapt_config(config, params):
    for pipeline in config.sections():
        pipeline_config = configparser.ConfigParser()
        pipeline_config[pipeline] = {}
        for key, val in config.items(pipeline):
            pipeline_config[pipeline][key] = val
        openmvs_save_config(
            pipeline_config,
            params["path_to_config"]
            + "/"
            + params["config_subname"]
            + pipeline
            + ".cfg",
        )


def openmvs_save_config(config, path_to_file):
    """
    config - config
    path_to_file - path to save file
    """
    # save file in .cfg format (pipeline related options)
    save_config(config, path_to_file)


def openmvs_change_config(params):
    config = configparser.ConfigParser()
    config = openmvs_adapt_config_to_quality(config, params["quality_mode"])
    config = openmvs_adapt_to_runtime(config, params["path_to_project"])
    openmvs_adapt_config(config, params)


#############################################################
#       RUNTIME CONFIGS                                     #
#                                                           #
#############################################################


def general_save_config(config, path_to_file):
    # save file in string format (deep_run, make_mesh, use_gpu, verbosity options)
    with open(path_to_file, "w") as file:
        file.write(config)


# passed only from command line
def general_adapt_to_runtime(params):
    config = ""
    config += f"{1 if params['deep_run'] == True else 0}\n"
    config += f"{params['quality_mode']}\n"
    config += f"{1 if params['make_mesh'] == True else 0}\n"
    config += f"{params['verbosity']}\n"
    config += f"{-1 if params['use_gpu'] == True else -2}\n"
    general_save_config(
        config,
        params["path_to_config"] + "/" + params["config_subname"] + "RUNTIME" + ".txt",
    )
