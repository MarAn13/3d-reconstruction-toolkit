import argparse
import os
from utils.pipeline import convert, make_masks, deblur


def main(path_to_workspace):
    path_to_video = os.path.join(path_to_workspace, "video.mp4")
    path_to_images = os.path.join(path_to_workspace, "images")
    path_to_masks = os.path.join(path_to_workspace, "masks/segment")
    classes = None
    device = "cuda:0"
    print("CONVERT..")
    convert.convert_video_to_images(path_to_video, path_to_images)
    print("DEBLUR..")
    deblur.deblur_driver(path_to_images, "wiener")
    print("MAKE MASKS..")
    make_masks.mask_driver(path_to_images, path_to_masks, classes, device, False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="data-processing-pipeline",
        description="Data processing pipeline (convert, masks, ...)",
    )
    parser.add_argument("path_to_workspace", type=str, help="path to workspace")
    args = parser.parse_args()
    print("DATA PROCESSING PARAMETERS:", args.path_to_workspace)
    main(args.path_to_workspace)
