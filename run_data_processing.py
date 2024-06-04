import argparse
import os
from utils.pipeline import convert, make_masks, deblur, make_run_info


def main(run_dir_name):
    # setup paths
    path_to_cur_dir = os.getcwd()
    path_to_workspace = os.path.join(path_to_cur_dir, "runs", run_dir_name)
    path_to_json = os.path.join(
        path_to_cur_dir, "runs-data", "options", f"options-{run_dir_name}.json"
    )
    path_to_video = os.path.join(
        path_to_cur_dir, "runs-data", "videos", f"video-{run_dir_name}.mp4"
    )
    path_to_images = os.path.join(path_to_workspace, "images")
    path_to_masks = os.path.join(path_to_workspace, "masks/segment")
    # create directories
    os.mkdir(path_to_images)
    os.makedirs(path_to_masks, exist_ok=True)
    # run pipeline
    classes = None
    device = "cuda:0"
    print("MAKE RUNTIME CONFIGS..")
    params = make_run_info.make_info(path_to_json, path_to_workspace)
    print(
        f"RUN INFO\n\tdeblur: {params['RUNTIME']['deblur_method']}\n\tmasking: {params['RUNTIME']['masking_method']}\n\tuse gpu: {params['RUNTIME']['use_gpu']}"
    )
    if params["RUNTIME"]["use_gpu"]:
        device = "cuda:0"
    else:
        device = "cpu"
    print("CONVERT..")
    convert.convert_video_to_images(path_to_video, path_to_images)
    if params["RUNTIME"]["deblur_method"] != "none":
        print("DEBLUR..")
        deblur.deblur_driver(path_to_images, params["RUNTIME"]["deblur_method"])
    if params["RUNTIME"]["masking_method"] != "none":
        print("MAKE MASKS..")
        make_masks.mask_driver(path_to_images, path_to_masks, classes, device, False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="data-processing-pipeline",
        description="Data processing pipeline (convert, masks, ...)",
    )
    parser.add_argument("run_dir_name", type=str, help="run directory name")
    args = parser.parse_args()
    print("DATA PROCESSING PARAMETERS:", args.run_dir_name)
    main(args.run_dir_name)
