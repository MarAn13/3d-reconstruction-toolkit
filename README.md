# 3d-reconstruction-toolkit

`3d-reconstruction-toolkit` lets you easily reconstruct 3D models based on video sequence using provided application and your own hardware. Reconstruct 3D models via classic COLMAP-OpenMVS pipeline or its more modern variant (ALIKED + LightGlue) choosing reconstruction options based on your preferences and hardware limitations.

Contents
========


* [Why?](#why)
* [Installation](#installation)
* [Usage](#usage)



### Why?

I wanted a tool that allows you to:

+ Reconstruct 3D models with barely any setup.
+ Reconstruct 3D models based on your preferences (quality, computation time, hardware limitations).
+ Reconstruct 3D models on the go - record video, choose options, reconstruct!
+ Share 3D models of real items.
+ View reconstructed 3D models without any additional tools.
+ Use beautifull minimalistic interface. 

`3d-reconstruction-toolkit` checks all of those boxes.

### Installation
---

Install this repository and setup conda environment

```bash
$ git clone https://github.com/MarAn13/3d-reconstruction-toolkit.git && cd 3d-reconstruction-toolkit
$ conda env create --name <ENV_NAME> --file environment.yaml
```

> **Warning**
> Don't forget to install [dependencies](#dependencies) first!

Change 2 lines in the `app_pipeline.sh` file

```bash
colmap_dir="<PATH TO COLMAP BINARY>"
openmvs_dir="<PATH TO OPENMVS BINARY>"
```

#### Dependencies
---

- [COLMAP-3.9.1](https://github.com/colmap/colmap/releases/tag/3.9.1)
- [OpenMVS-2.3.0](https://github.com/cdcseacave/openMVS/releases/tag/v2.3.0)
- [LightGlue](https://github.com/cvg/LightGlue)

Download COLMAP and OpenMVS binaries.

Clone and install LightGlue

```bash
$ git clone https://github.com/cvg/LightGlue.git && cd LightGlue
$ python -m pip install -e .
```

### Usage
---

> **Note**
> Setup ssh server on your local machine first (e.g. [setup OpenSSH on Windows 11](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=gui)).

1. Open the app.
1. Provide ssh parameters from the settings page.
2. Record video.
3. Select reconstruction options.
4. Open history page.
5. Enjoy!