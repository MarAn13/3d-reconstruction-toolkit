from ultralytics import YOLO
from datetime import datetime, timezone
import cv2
import numpy as np
from tqdm.auto import tqdm
import os


def gen_cur_time():
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H-%M-%S-%f")


def yolov8_predict(model_name, path_to_images, classes, device, save):
    run_name = f"run-{gen_cur_time()}"
    model = YOLO(model_name)
    results = model.predict(
        path_to_images,
        save=save,
        imgsz=640,
        classes=classes,
        device=device,
        project="predict-results",
        name=run_name,
        verbose=False,
    )
    return results


def create_masks(results, path_to_masks):
    n_frames = len(results)
    n_unmasked_frames = 0
    for image_res in tqdm(results, desc="Yolov8 masks processing.."):
        pixel_masks = []
        for obj_res in image_res:
            pixel_masks.append(obj_res.masks.xy[0].astype(np.int32))
        img = np.zeros(image_res.orig_shape)
        for mask in pixel_masks:
            cv2.fillPoly(img, [mask], 255)
        # process frames with 0 detected objects
        if len(pixel_masks) == 0:
            img.fill(255)
            n_unmasked_frames += 1
        split_path = image_res.path.split("\\")
        if len(split_path) == 1:
            split_path = split_path[0].split("/")
        mask_filename = split_path[-1]
        mask_path = path_to_masks + "\\" + mask_filename + ".png"
        cv2.imwrite(mask_path, img)
    return n_frames - n_unmasked_frames, n_frames


def mask_driver(path_to_images, path_to_masks, classes, device, save):
    path_to_cur_dir = os.path.dirname(os.path.realpath(__file__))
    path_to_model = os.path.join(path_to_cur_dir, "yolov8s-seg-co3d.pt")
    results = yolov8_predict(path_to_model, path_to_images, classes, device, save)
    n_masked_frames, n_frames = create_masks(results, path_to_masks)
    return n_masked_frames, n_frames, results
