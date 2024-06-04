import json
import os
from . import make_configs


def read_json(path_to_json):
    with open(path_to_json, "r") as file:
        data = json.load(file)
    return data


def convert_options_to_params(options, path_to_workspace):
    # get params from options
    quality_mode = options["reconstructionQuality"]
    use_gpu = options["computingUnit"] == "gpu"
    deep_run = options["reconstructionMethod"] == "deep"
    make_mesh = options["reconstructionRepresentation"] == "mesh"
    deblur_method = options["deblurringMethod"]
    masking_method = options["maskingMethod"]

    # setup paths
    project_name = "project"
    path_to_project = os.path.join(path_to_workspace, project_name)
    path_to_config = os.path.join(path_to_project, "configs")
    # init params
    params = {
        "COLMAP": {
            "path_to_workspace": path_to_workspace,
            "path_to_images": os.path.join(path_to_workspace, "images"),
            "path_to_masks": os.path.join(path_to_workspace, "masks", "segment"),
            "path_to_database": os.path.join(path_to_project, "database.db"),
            "path_to_project": path_to_project,
            "path_to_config": path_to_config,
            "config_subname": "COLMAP-3.9.1-config-",
            "data_mode": "video",
            "quality_mode": quality_mode,
            "shared_camera": True,
            "use_gpu": use_gpu,
            "deep_run": deep_run,
        },
        "OpenMVS": {
            "path_to_workspace": path_to_workspace,
            "path_to_project": path_to_project,
            "path_to_config": path_to_config,
            "config_subname": "OpenMVS-2.3.0-config-",
            "quality_mode": quality_mode,
        },
        "RUNTIME": {
            "path_to_config": path_to_config,
            "config_subname": "config-",
            "deep_run": deep_run,
            "quality_mode": quality_mode,
            "verbosity": 2,
            "make_mesh": make_mesh,
            "use_gpu": use_gpu,
            "deblur_method": deblur_method,
            "masking_method": masking_method,
        },
    }
    return params


def make_info(path_to_json, path_to_workspace):
    options = read_json(path_to_json)
    params = convert_options_to_params(options, path_to_workspace)
    # make project dir
    os.mkdir(params["COLMAP"]["path_to_project"])
    make_configs.make_project_info(
        params["COLMAP"]["path_to_project"], params["COLMAP"]
    )
    # make configs dir
    os.mkdir(params["COLMAP"]["path_to_config"])
    path_to_cur_dir = os.getcwd()
    path_to_default_config = f"{path_to_cur_dir}/COLMAP-3.9.1-config-default.ini"
    make_configs.colmap_change_config(path_to_default_config, params["COLMAP"])
    make_configs.openmvs_change_config(params["OpenMVS"])
    make_configs.general_adapt_to_runtime(params["RUNTIME"])
    return params
