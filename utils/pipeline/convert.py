import cv2
import numpy as np
from tqdm.auto import tqdm
import os


# convert video to images
def convert_video_to_images(path_to_video, path_to_images, n_frames=100):
    # parameters:
    #   path_to_video - absolute or relative path to video file
    #   path_to_images - absolute or relative path to result frames folder
    #   n_frames - number of frames to sample
    cap = cv2.VideoCapture(path_to_video)
    count = 0
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    frame_list = np.linspace(0, total_frames, n_frames, dtype=int)
    # folder = video_path.split('.')[0]
    frame_count = 0
    print("Video info")
    print("\tvideo fps:", fps)
    print("\tvideo total frames:", total_frames)
    print("\tvideo frames selected:", n_frames)
    pbar = tqdm(total=total_frames)
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        if count in frame_list:
            cv2.imwrite(f"{path_to_images}/frame{str(frame_count).zfill(6)}.jpg", frame)
            frame_count += 1
        count += 1
        pbar.update(1)
    pbar.close()
    cap.release()
    cv2.destroyAllWindows()


# convert images to video
def convert_images_to_video(path_to_images, path_to_video):
    fc = cv2.VideoWriter_fourcc(*"mp4v")
    video = cv2.VideoWriter(path_to_video, fc, 30, (2000, 1109))
    for file in tqdm(
        sorted(os.listdir(path_to_images)), desc="Convertion in progress.."
    ):
        file_path = os.path.join(path_to_images, file)
        image = cv2.imread(file_path)
        video.write(image)
