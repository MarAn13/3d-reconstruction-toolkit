import cv2
import numpy as np
from skimage import measure, restoration
import os
import tqdm
from joblib import Parallel, delayed


##########################################################################################
# joblib with tqdm                                                                       #
# provided by https://github.com/joblib/joblib/issues/972                                #
##########################################################################################
class ParallelTqdm(Parallel):
    """joblib.Parallel, but with a tqdm progressbar

    Additional parameters:
    ----------------------
    total_tasks: int, default: None
        the number of expected jobs. Used in the tqdm progressbar.
        If None, try to infer from the length of the called iterator, and
        fallback to use the number of remaining items as soon as we finish
        dispatching.
        Note: use a list instead of an iterator if you want the total_tasks
        to be inferred from its length.

    desc: str, default: None
        the description used in the tqdm progressbar.

    disable_progressbar: bool, default: False
        If True, a tqdm progressbar is not used.

    show_joblib_header: bool, default: False
        If True, show joblib header before the progressbar.

    Removed parameters:
    -------------------
    verbose: will be ignored


    Usage:
    ------
    >>> from joblib import delayed
    >>> from time import sleep
    >>> ParallelTqdm(n_jobs=-1)([delayed(sleep)(.1) for _ in range(10)])
    80%|████████  | 8/10 [00:02<00:00,  3.12tasks/s]

    """

    def __init__(
        self,
        *,
        total_tasks: int | None = None,
        desc: str | None = None,
        disable_progressbar: bool = False,
        show_joblib_header: bool = False,
        **kwargs,
    ):
        if "verbose" in kwargs:
            raise ValueError(
                "verbose is not supported. "
                "Use show_progressbar and show_joblib_header instead."
            )
        super().__init__(verbose=(1 if show_joblib_header else 0), **kwargs)
        self.total_tasks = total_tasks
        self.desc = desc
        self.disable_progressbar = disable_progressbar
        self.progress_bar: tqdm.tqdm | None = None

    def __call__(self, iterable):
        try:
            if self.total_tasks is None:
                # try to infer total_tasks from the length of the called iterator
                try:
                    self.total_tasks = len(iterable)
                except (TypeError, AttributeError):
                    pass
            # call parent function
            return super().__call__(iterable)
        finally:
            # close tqdm progress bar
            if self.progress_bar is not None:
                self.progress_bar.close()

    __call__.__doc__ = Parallel.__call__.__doc__

    def dispatch_one_batch(self, iterator):
        # start progress_bar, if not started yet.
        if self.progress_bar is None:
            self.progress_bar = tqdm.tqdm(
                desc=self.desc,
                total=self.total_tasks,
                disable=self.disable_progressbar,
                unit="tasks",
            )
        # call parent function
        return super().dispatch_one_batch(iterator)

    dispatch_one_batch.__doc__ = Parallel.dispatch_one_batch.__doc__

    def print_progress(self):
        """Display the process of the parallel execution using tqdm"""
        # if we finish dispatching, find total_tasks from the number of remaining items
        if self.total_tasks is None and self._original_iterator is None:
            self.total_tasks = self.n_dispatched_tasks
            self.progress_bar.total = self.total_tasks
            self.progress_bar.refresh()
        # update progressbar
        self.progress_bar.update(self.n_completed_tasks - self.progress_bar.n)


##########################################################################################
# SECTION                                                                                #
# END                                                                                    #
##########################################################################################


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


def deblur_driver_util(file_path, method):
    image = cv2.imread(file_path)
    deblurred_image = deblur_single_driver(image, method=method)
    cv2.imwrite(file_path, deblurred_image)


def deblur_driver(path_to_images, method):
    images_abs_paths = [
        os.path.join(path_to_images, file)
        for file in sorted(os.listdir(path_to_images))
    ]
    ParallelTqdm(
        n_jobs=-1,
        total_tasks=len(images_abs_paths),
        desc="Deblurring..",
    )(
        (
            delayed(deblur_driver_util)(image_abs_path, method)
            for image_abs_path in images_abs_paths
        ),
    )
