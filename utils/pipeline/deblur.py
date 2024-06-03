import cv2
import numpy as np
from skimage import measure, restoration
import os
from tqdm.auto import tqdm


def variance_of_laplacian(image):
    # compute the Laplacian of the image and then return the focus
    # measure, which is simply the variance of the Laplacian
    return cv2.Laplacian(image, cv2.CV_64F).var()


def compute_blur_metric(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    return measure.blur_effect(gray)


def is_image_blurred(image, threshold=100.0):
    # load the image, convert it to grayscale, and compute the
    # focus measure of the image using the Variance of Laplacian
    # method
    # gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    # compute the Laplacian of the image and then return the focus
    # measure, which is simply the variance of the Laplacian
    laplacian_var = cv2.Laplacian(image, cv2.CV_64F).var()
    # compute blur metric
    blur_metric = compute_blur_metric(image)
    # if the focus measure is less than the supplied threshold,
    # then the image should be considered "blurry"
    status_blurred = False
    if laplacian_var < threshold:
        status_blurred = True
    return status_blurred, laplacian_var, blur_metric


# better to use weiner - it is faster with same +- results
def deblur_wiener(image):
    psf = np.ones((5, 5)) / 25
    deblurred_image = restoration.wiener(image, psf, 0.01)
    return deblurred_image


# auto wiener version
def deblur_wiener_auto(image):
    psf = np.ones((5, 5)) / 25
    deblurred_image, _ = restoration.unsupervised_wiener(image, psf)
    return deblurred_image


def deblur_richardson_lucy(image):
    psf = np.ones((5, 5)) / 25
    deblurred_image = restoration.richardson_lucy(image, psf, 5)
    return deblurred_image


def deblur_single_driver(image, method="wiener"):
    # Convert the image to floating point type and normalize the values to the range [0, 1]
    image = image.astype(np.float32) / 255.0
    # Split the image into separate color channels
    B, G, R = cv2.split(image)
    if method == "wiener":
        # Apply Wiener deconvolution to each channel separately
        deblurred_channels = [deblur_wiener(channel) for channel in [B, G, R]]
    if method == "wiener_auto":
        # Apply Wiener deconvolution to each channel separately
        deblurred_channels = [deblur_wiener_auto(channel) for channel in [B, G, R]]
    elif method == "richardson_lucy":
        # Apply Richardson-Lucy deconvolution to each channel separately
        deblurred_channels = [deblur_richardson_lucy(channel) for channel in [B, G, R]]
    # Merge the deblurred color channels back into an RGB image
    deblurred_image = cv2.merge(deblurred_channels)
    # Convert deblurred image back to 8-bit unsigned integer format
    deblurred_image = np.clip(deblurred_image * 255, 0, 255).astype(np.uint8)
    return deblurred_image


def deblur_driver(path_to_images, method):
    for file in tqdm(sorted(os.listdir(path_to_images)), desc="Deblurring.."):
        file_path = os.path.join(path_to_images, file)
        image = cv2.imread(file_path)
        deblurred_image = deblur_single_driver(image, method=method)
        cv2.imwrite(file_path, deblurred_image)
