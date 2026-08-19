<img src="https://raw.githubusercontent.com//MELDProject/meld_graph/main/docs/images/MELD_logo.png" alt="MELD logo" width="100" align="left"/> 

# MELD-PostOp
**Publication**: [here](https://onlinelibrary.wiley.com/doi/epdf/10.1002/epi.70450) 

MELD-PostOp is an automated tool for segmenting resection cavities on postoperative T1w MRI scans of epilepsy patients, developed using nnU-Net framework.
This page provides instructions for installing the pretrained MELD-PostOp model and running inference on new patients. 


### LICENSE 
We kindly ask all MELD-PostOp users to complete the MELD-PostOp registration form. After submission, you will receive a license file, which is required to use MELD-PostOp version v1.0.0.

[**MELD-PostOp Registration Form**](https://forms.gle/Sm8ZDUbU8GThfqwb6)

Your email address will also be added to the MELD-PostOp mailing list so we can keep you informed about bug fixes and new releases.

### System requirements 
- The instruction below was tested on Linux (Ubuntu 22.04.5)
- Python: 3.9 or newer
- Hardware: GPU is strongly recommended 

## 1. MELD-PostOp installation & setup
### 1.1 Create a virtual environment
We recommend using **Anaconda** to manage the Python environment and dependencies. 
Please follow the official installation instructions for [Anaconda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html). 

```bash
conda create -n meldpostop python=3.13.5
conda activate meldpostop
```

### 1.2 Install nnU-Net v2 
MELD-PostOp is developed on the nnU-Net framework. For additional details, please refer to the official [nnU-Net](https://github.com/MIC-DKFZ/nnUNet). 
```bash
pip install nnunetv2
```

### 1.3 Download the pretrained model 
Download the pretrained MELD-PostOp model archive (_MELD-PostOp.zip_) from Figshare and unzip it locally:
- [MELD-PostOp Figshare](https://figshare.com/s/c5a3d4a5604b229eeb5f)
- version: v1.0.0

### 1.4 License setup 
A valid **MELD-PostOp licencse file** is required to run inference. After completing the MELD-PostOp registration form, you will receive a license file. 
Place the license file in: `/MELD-PostOp/model/`. Inference will fail if no valid license file is found. 

### 1.5 Directory structure 
After completing the installation and setup, the MELD-PostOp directory should have the following structure: 
   ```
   MELD-PostOp/
   ├── input_001/
   ├── bin/
   │   └── run_meldpostop_v1.sh
   ├── model/
   │   ├── (MELD-PostOp license file) 
   │   └── Dataset001_MELDPostOp_v1.0.0/
   │       └── nnUNetTrainer__nnUNetPlans__3d_fullres/     < (pretrained model weights) 
   ```


## 2. Data preparation 
### 2.1 Input data requirements 
- Input images must be postoperative **T1-weighted MRI scans**
- Images must be in **NIfTi format** (`.nii` or `.nii.gz`)
- **NOTE:** MELD-PostOp was trained on postoperative T1w MRI scans from patients who had lesionectomy or lobectomy. It may not be appropriate for other procedures (e.g. laser ablation, thermocoagulation etc).

### 2.2 File naming 
- All input files must follow nnU-Net naming conventions
- Each file name must include:
     - a subject id
     - the modality suffix `_0000`, indicating T1w
- Exmaple: `sub-<subject_id>_0000.nii.gz`

### 2.3 Input directory 
- Upon download, an inital input directory (`input_001`) is provided
- To process multiple datasets, create additional input directories named `input_<key>`, where `<key>` is a dataset identifier (we recommend a 3-digit number, e.g. `input_003`,`input_027`)
- Place all NIfTI files for a given dataset inside the corresponding input directory
- Output directories are generated automatically:
     - `input_001` → `output_001`
     - `input_002` → `output_002`
     - No manual creation of output directories is required 

## 3. Running MELD-PostOp inference 
### 3.1 Directory&command setup 
```bash
cd path/to/MELD-PostOp
chmod +x bin/run_meldpostop_v1.sh
```

### 3.2 Inference 
To run inference on new patients, execute: 
```bash
bin/run_meldpostop_v1.sh -m </path/to/MELD-PostOp> -k <key> 
```

## Additional information
After running inference with MELD-PostOp, you may wish to perform **external validation** of the model on your dataset. 
Please refer to the following link for detailed instructions: 
- [notebooks](notebooks/)

If you wish to recerate figures in the manuscript, please refer to the following link for detailed instructions: 
- [figures](figures/)

