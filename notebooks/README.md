# 🧠 MELD-PostOp External Validation: Performance Breakdown

This pipeline reproduces the performance breakdown analysis for **MELD-PostOp** for external validation purposes. It computes segmentation accuracy and analyse performance across demographic, imaging, surgical, and pathological factors.

---

## Overview

The analysis requires additional files:

1. **Manual resection cavity masks** (ground truth segmentations)  
2. **A subject-level CSV file** containing demographic, imaging, pathology, and performance metrics  


Using these inputs, the pipeline:

1. Computes DSC, manual mask volume, and image isotropy: `metric_computation.ipynb`
2. Analyse performance by clinical and imaging subtroups: `performance_analysis.ipynb`
3. (additional) Computes positive predictive value and number of false positive clusters: `cluster_analysis.ipynb` 

---

## ◼️ Required Inputs 

### 1. Manual Resection Cavity Masks

Binary masks representing the resection cavity for each subject.

- Must be spatially aligned with the corresponding postoperative image  
- One mask per subject  
- Used as ground truth for DSC and volume calculation  
- Example directory: `MELD-PostOp/ground_truth/sub-MELD_001_gt.nii.gz`


### 2. Subject Metadata CSV

A single CSV file with the format below:

| column name | description |
|------------|-------------|
| id | Unique subject identifier (e.g. `MELD_001`) |
| age_at_surgery | Age at surgery (years, numeric) |
| age_at_preop | Age at preoperative scan (years, numeric) |
| sex | 0 = male, 1 = female |
| resection_side | `L` or `R` |
| resection_lobe | `frontal`, `temporal`, `parietal`, `occipital`, `limbic`, `insular`, or `other` |
| pathology | Primary pathology code (see below) |
| pathology_other | Secondary pathology code (optional; dual pathology) |
| DSC | Dice Similarity Coefficient between prediction and manual mask (0–1) |
| manual_volume | Ground truth cavity volume (cm³) |
| image_isotropy | `isotropic` or `anisotropic` |
| field_strength | `3T` or `1.5T` |

- DSC, manul_volume, image_isotropy can be computed with `metric_computation.ipynb`


**Pathology Codes** 
primary (`pathology`) and optional secondary (`pathology_other`) pathology are encoded as: 

```ini
1  = FCD 1
2  = FCD 2A
3  = FCD 2B
4  = FCD 3A
5  = FCD 3B
6  = FCD 3C
7  = FCD 3D
8  = FCD 2 other
9  = FCD other
10 = HS
11 = Hippocampal gliosis
12 = Cortical gliosis
13 = DNET
14 = Ganglioglioma
15 = Other LEAT
16 = Polymicrogyria
17 = PNH
18 = Cavernoma
19 = Non-specific
21 = Normal
22 = HH
23 = Other
25 = MOGHE
26 = MCD
27 = LEAT xdef
28 = Astrocytoma
29 = PLNTY
30 = mMCD
31 = Glioblastoma / high-grade tumour
```
Leave `pathology_other` blank if no dual pathology is present 

---

## ◼️ Pipeline

### 1. `metric_computation.ipynb`
**Input**: 
-  subject metadata csv file (with blank DSC, manual_volume, image_isotropy columns)
-  predicted masks, ground truth masks, postop MRI

**Computation**: 
- DSC: computed between predicted cavity mask and manual ground truth 
- Manual volume: volume in cm³ of ground truth mask
- Image isotropy: extract isotropy with tolerance threshold of +/-0.1 mm

**Output**:
- subject metadata csv file (updated ver. of input csv)


### 2. `performance_analysis.ipynb`
**Input**: 
-  subject metadata csv file

**Compuation**: 
- Performs pairwise Mann Whitney U/ Kruskal Wallis/ Spearman's rank correlation test
- Corrects p value with Bonferroni adjustment for multiple comparison

**Output**: 
- A table for each subgroup including:
  - Number and percentage of subject, median DSC + IQR, mean DSC + SD
- A table summarising p values before and after correction for each comparison between two variables


### 3. `cluster_analysis.ipynb`
**Input**: 
-  subject metadata csv file
-  predicted masks, ground truth masks

**Computation**: 
- Calculates positive predictive value and number of false positive clusters on subject level

**Output**: 
- A table including:
  - subject ids, number of cluster in gt and predicted masks, PPV, number of FP clusters
- Median FP clusters, mean PPV 

---


