#!/usr/bin/env python3
"""Read meldpostop_config.ini, validate it, and print shell `export` lines.

Used by run_meldpostop.sh:
    eval "$(python config.py --config meldpostop_config.ini)"
"""
import argparse
import configparser
import shlex
import sys
from pathlib import Path


def load_config(ini_path: Path) -> dict:
    if not ini_path.is_file():
        raise SystemExit(f"ERROR: config file not found: {ini_path}")

    cp = configparser.ConfigParser()
    cp.read(ini_path)

    try:
        root = Path(cp.get("paths", "meldpostop_weight_path").strip()).expanduser()
    except (configparser.NoSectionError, configparser.NoOptionError):
        raise SystemExit("ERROR: [paths] meldpostop_weight_path missing in config")

    if "/path/to/" in str(root):
        raise SystemExit(
            f"ERROR: meldpostop_weight_path is still the placeholder ({root}). "
            f"Edit {ini_path}"
        )
    if not root.is_dir():
        raise SystemExit(f"ERROR: meldpostop_weight_path is not a directory: {root}")
    root = root.resolve()

    get = lambda opt, default: cp.get("inference", opt, fallback=default).strip()
    getb = lambda opt, default: cp.getboolean("inference", opt, fallback=default)

    return {
        "MELD_ROOT": str(root),
        "MODEL_DIR": str(root / "model"),
        "DATASET_ID": get("dataset_id", "001"),
        "NN_CONFIGURATION": get("configuration", "3d_fullres"),
        "SAVE_PROBABILITIES": "1" if getb("save_probabilities", True) else "0",
        "DISABLE_TTA": "1" if getb("disable_tta", True) else "0",
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--config",
        type=Path,
        default=Path(__file__).resolve().parent / "meldpostop_config.ini",
    )
    args = ap.parse_args()
    for k, v in load_config(args.config).items():
        print(f"export {k}={shlex.quote(v)}")


if __name__ == "__main__":
    sys.exit(main())
