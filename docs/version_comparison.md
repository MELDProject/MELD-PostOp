
# What's new in MELD-PostOp v2.0.0?

MELD-PostOp v2.0.0 includes an updated training dataset, alongside improved segmentation performance compared with v1.0.0.

#### Dataset

| **Dataset** | **v1.0.0** | **v2.0.0** |
|---|---:|---:|
| Training data | 965 | 992 (+28 new scans, 1 excluded) |
| Test data | 137 | 139 (+2 new scans in the independent test cohort) |
In addition, **286 training segmentations have been updated** in v2.0.0.


#### Improved performance in selective amygdalohippocampectomy

Version 2.0.0 also improves segmentation in selective amygdalohippocampectomy cases. In particular, cases where v1.0.0 missed hippocampal resections are better segmented by v2.0.0.


#### Example comparison

<!-- Add v1.0.0 vs v2.0.0 comparison image here -->
![MELD-PostOp v1.0.0 vs v2.0.0 comparison](path/to/comparison_image.png)


#### Segmentation performance

| **Metric** | **v1.0.0** | **v2.0.0** |
|---|---:|---:|
| Median DSC [IQR] | 0.85 [0.74–0.92] | **0.86 [0.78–0.93]** |
| PPV | 0.93 | **0.94** |
| Median FP clusters [IQR]  | 0 [0–0] | 0 [0–0] |
| Cases with DSC > 0 | 135/137 (98.5%) | 137/139 (98.6%) |
| Cases with DSC > 0.5  | 128/137 (93.4%) | **132/139 (95.0%)** |
*DSC: Dice similarity coefficient; IQR: interquartile range; PPV: positive predictive value; FP: false-positive.*
