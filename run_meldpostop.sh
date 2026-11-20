#!/usr/bin/env bash
set -euo pipefail

##########################################################
# MELD-PostOp launcher (nnU-Net v2)
#
# Usage:
#   ./run_meldpostop.sh -k <KEY> [-c config.ini] [-f]
#
#   -k  unique key (letters, digits, . _ -); uses
#         <ROOT>/input_<KEY>  ->  <ROOT>/output_<KEY>
#   -c  config file (default: meldpostop_config.ini next to this script)
#   -f  overwrite an existing, non-empty output_<KEY>
##########################################################

SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/meldpostop_config.ini"
KEY=""
FORCE=0

usage() { echo "Usage: $(basename "$0") -k <KEY> [-c <config.ini>] [-f]"; }
die()   { echo "ERROR: $*" >&2; exit 1; }

while getopts "k:c:fh" opt; do
    case $opt in
        k) KEY="$OPTARG" ;;
        c) CONFIG_FILE="$OPTARG" ;;
        f) FORCE=1 ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

[[ -n "$KEY" ]] || { usage; die "-k <KEY> is required"; }
[[ "$KEY" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] \
    || die "Key '$KEY' invalid. Use letters, digits, '.', '_' or '-' (must start with letter/digit)."

############################################
# Environment checks
############################################
command -v python >/dev/null 2>&1 || die "python not found. Run: conda activate meldpostop"
command -v nnUNetv2_predict >/dev/null 2>&1 \
    || die "nnUNetv2_predict not found. Run: conda activate meldpostop"

############################################
# Load config
############################################
CONFIG_EXPORTS=$(python "${SCRIPT_DIR}/config.py" --config "$CONFIG_FILE")
eval "$CONFIG_EXPORTS"

INPUT_DIR="${MELD_ROOT}/input_${KEY}"
OUTPUT_DIR="${MELD_ROOT}/output_${KEY}"

[[ -d "$MODEL_DIR" ]] || die "Model directory not found: $MODEL_DIR"
[[ -d "$INPUT_DIR" ]] || die "Input directory not found: $INPUT_DIR"

############################################
# Model version
############################################
shopt -s nullglob
MODEL_CANDIDATES=("$MODEL_DIR"/Dataset${DATASET_ID}_*/)
shopt -u nullglob
[[ ${#MODEL_CANDIDATES[@]} -ge 1 ]] || die "No model folder Dataset${DATASET_ID}_* in $MODEL_DIR"
[[ ${#MODEL_CANDIDATES[@]} -eq 1 ]] || die "Multiple Dataset${DATASET_ID}_* folders in $MODEL_DIR"

MODEL_FOLDER=$(basename "${MODEL_CANDIDATES[0]}")          # Dataset001_MELDPostOp_v2.0.0
MODEL_VERSION="MELD-PostOp_${MODEL_FOLDER##*_}"            # MELD-PostOp_v2.0.0
TRAINER_DIR="${MODEL_CANDIDATES[0]}nnUNetTrainer__nnUNetPlans__${NN_CONFIGURATION}"
[[ -d "$TRAINER_DIR" ]] || die "Trained model folder not found: $TRAINER_DIR"

############################################
# License check
############################################
LICENSE_FILE=""
LICENSE_ID=""
shopt -s nullglob
for f in "$MODEL_DIR"/*.txt; do
    if id=$(grep -Eo "License ID:[[:space:]]*[0-9]{6}\b" "$f" | head -n1 | grep -Eo "[0-9]{6}"); then
        LICENSE_FILE="$f"; LICENSE_ID="$id"; break
    fi
done
shopt -u nullglob
[[ -n "$LICENSE_FILE" ]] || die "No valid license file (with 'License ID: XXXXXX') found in $MODEL_DIR"

############################################
# Output dir (key must be unique)
############################################
if [[ -d "$OUTPUT_DIR" && -n "$(ls -A "$OUTPUT_DIR")" && $FORCE -eq 0 ]]; then
    die "Output directory already exists and is not empty: $OUTPUT_DIR
       Key '$KEY' has been used. Choose a new key or pass -f to overwrite."
fi

############################################
# Count input files
############################################
mapfile -t ALL_FILES < <(find "$INPUT_DIR" -maxdepth 1 -type f \( -name "*.nii" -o -name "*.nii.gz" \))
mapfile -t CH0_FILES < <(find "$INPUT_DIR" -maxdepth 1 -type f \( -name "*_0000.nii" -o -name "*_0000.nii.gz" \))
NUM_FILES=${#ALL_FILES[@]}
NUM_SUBJECTS=${#CH0_FILES[@]}

[[ $NUM_FILES -gt 0 ]] || die "No .nii/.nii.gz files in $INPUT_DIR"
[[ $NUM_SUBJECTS -gt 0 ]] || die "No files named *_0000.nii(.gz) in $INPUT_DIR (nnU-Net naming required)"
if [[ $NUM_FILES -ne $NUM_SUBJECTS ]]; then
    echo "WARNING: $((NUM_FILES - NUM_SUBJECTS)) file(s) do not end in _0000 and will be ignored/may error."
fi

############################################
# Summary
############################################
echo
echo "============================================================================="
echo " MELD-PostOp"
echo "============================================================================="
echo " Key:            $KEY"
echo " Model version:  $MODEL_VERSION (model weight: $MODEL_FOLDER)"
echo " License file:   $LICENSE_FILE"
echo " License ID:     $LICENSE_ID"
echo " Input files:    $NUM_SUBJECTS subject(s) ($NUM_FILES nifti files)"
echo " Input dir:      $INPUT_DIR"
echo " Output dir:     $OUTPUT_DIR"
echo "============================================================================="

############################################
# nnU-Net environment
############################################
mkdir -p "$OUTPUT_DIR"
export nnUNet_results="$MODEL_DIR"
export nnUNet_raw="$MODEL_DIR/.nnunet_dummy_raw"
export nnUNet_preprocessed="$MODEL_DIR/.nnunet_dummy_preprocessed"
mkdir -p "$nnUNet_raw" "$nnUNet_preprocessed"

############################################
# metadata.json
############################################
METADATA_FILE="${OUTPUT_DIR}/metadata.json"
cat > "$METADATA_FILE" <<JSON
{
    "model_version": "$MODEL_VERSION",
    "dataset_key": "$KEY",
    "license_id": "$LICENSE_ID",
    "num_input_files": $NUM_SUBJECTS,
    "input_dir": "$INPUT_DIR",
    "output_dir": "$OUTPUT_DIR",
    "timestamp": "$(date +"%Y-%m-%d %H:%M:%S")"
}
JSON
echo "Metadata written to $METADATA_FILE"

############################################
# Citation
############################################
echo
echo
echo "#############################################################################"
echo "Please cite the following paper when using MELD-PostOp:"
echo "Seo J, Ripart M, Kaas H, Kronlage C, Sinclair B, Vivash L, et al."
echo "Automated segmentation of postsurgical resection cavities on magnetic "
echo "resonance imaging in focal epilepsy: A Multicentre Epilepsy Lesion"
echo "Detection study. Epilepsia. 2026; 00: 1–18. https://doi.org/10.1002/epi.70450"
echo "#############################################################################"
echo

############################################
# Inference
############################################
EXTRA_ARGS=()
[[ "$SAVE_PROBABILITIES" == "1" ]] && EXTRA_ARGS+=(--save_probabilities)
[[ "$DISABLE_TTA" == "1" ]] && EXTRA_ARGS+=(--disable_tta)

nnUNetv2_predict \
    -i "$INPUT_DIR" \
    -o "$OUTPUT_DIR" \
    -d "$DATASET_ID" \
    -c "$NN_CONFIGURATION" \
    "${EXTRA_ARGS[@]}"

echo "-----------------------------------------------------------------------------"
echo "Inference completed successfully."
echo "Results saved in $OUTPUT_DIR"
echo "-----------------------------------------------------------------------------"
