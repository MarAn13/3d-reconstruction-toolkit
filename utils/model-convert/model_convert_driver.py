import argparse
from gltflib import GLTF
import open3d as o3d


def convert_mesh_to_glb(path_to_model, path_to_converted_model):
    """
    path_to_model: absolute or relative path to .glb model (without included resources)
    path_to_converted_model: absolute or relative path to converted .glb model (with included resources)
    """
    # pass model with texture to gltf converter
    gltf = GLTF.load(path_to_model, load_file_resources=True)
    gltf.export(path_to_converted_model)


def convert_pointcloud_to_glb(path_to_model, path_to_converted_model):
    """
    path_to_model: absolute or relative path to .glb model (without included resources)
    path_to_converted_model: absolute or relative path to converted .glb model (with included resources)
    """
    mesh = o3d.io.read_triangle_mesh(path_to_model, True)
    o3d.io.write_triangle_mesh(path_to_converted_model, mesh)


def main(path_to_model, path_to_converted_model, mode):
    if mode == "mesh":
        convert_mesh_to_glb(path_to_model, path_to_converted_model)
    elif mode == "pointcloud":
        convert_pointcloud_to_glb(path_to_model, path_to_converted_model)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="data-processing-pipeline",
        description="Data processing pipeline (convert, masks, ...)",
    )
    parser.add_argument(
        "path_to_model",
        type=str,
        help="absolute or relative path to .glb model (without included resources)",
    )
    parser.add_argument(
        "path_to_converted_model",
        type=str,
        help="absolute or relative path to converted .glb model (with included resources)",
    )
    parser.add_argument("mode", type=str, help="pointcloud or mesh")
    args = parser.parse_args()
    print(
        "MODEL CONVERTING PARAMETERS:",
        args.path_to_model,
        args.path_to_converted_model,
        args.mode,
    )
    main(args.path_to_model, args.path_to_converted_model, args.mode)
