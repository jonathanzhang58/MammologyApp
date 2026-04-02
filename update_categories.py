"""
Script to programmatically update categories in function_list.m
based on patient data from the Excel spreadsheet.

Usage:
    python update_categories.py                  # dry run (prints changes, no file modification)
    python update_categories.py --apply          # applies changes to function_list.m
"""

import re
import sys
import os
import openpyxl

# --- Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MATLAB_FILE = os.path.join(SCRIPT_DIR, "function_list.m")
EXCEL_FILE = os.path.join(
    SCRIPT_DIR,
    "teaching file - mammo specific files",
    "mammo - patient data and spreadsheets",
    "Final List - consolidated eligible pts with details_2-07-2025.xlsx",
)

# Excel column indices (0-based)
COL_PTID = 1
COL_DENSITY = 24
COL_BASELINE = 27
COL_FINDING_TYPE = 28
COL_RETROGLANDULAR = 31
COL_FINDING_EDGE = 32
COL_TOMO_ONLY = 34

# Category names in order, paired with their column index
CATEGORY_COLUMNS = [
    ("Density", COL_DENSITY),
    ("Baseline", COL_BASELINE),
    ("FindingType", COL_FINDING_TYPE),
    ("RetroglandularFat", COL_RETROGLANDULAR),
    ("FindingEdge", COL_FINDING_EDGE),
    ("FindingTomo-only", COL_TOMO_ONLY),
]


def ptid_to_image_key(ptid: str) -> str | None:
    """Convert a BITF patient ID to the funcStruct image key string."""
    if not ptid or not ptid.startswith("BITF"):
        return None
    num_str = ptid[4:]  # strip "BITF"
    try:
        num = int(num_str)
    except ValueError:
        return None

    if num <= 999:
        # BITF0000XXX -> Images/XXX_CCMLO_wbenign.jpg (3-digit zero-padded)
        return f"Images/{num:03d}_CCMLO_wbenign.jpg"
    elif num >= 1000000 and num <= 1999999:
        # BITF1000XXX -> Images/1000XXX_CCMLO_wbenign.jpg (7-digit)
        return f"Images/{num}_CCMLO_wbenign.jpg"
    else:
        return None


def build_category_map(excel_path: str) -> dict[str, list[str]]:
    """
    Read the Excel file and build a mapping:
      image_key -> list of category strings to append (e.g., ["Density_3", "Baseline_2"])
    """
    wb = openpyxl.load_workbook(excel_path, read_only=True, data_only=True)
    ws = wb.active

    cat_map = {}
    for row in ws.iter_rows(min_row=2):
        ptid = row[COL_PTID].value
        if not ptid:
            continue
        ptid = str(ptid).strip()

        image_key = ptid_to_image_key(ptid)
        if image_key is None:
            continue

        categories = []
        for cat_name, col_idx in CATEGORY_COLUMNS:
            val = row[col_idx].value
            if val is not None and str(val).strip() != "":
                # Convert to int if it's a float (Excel often stores numbers as float)
                if isinstance(val, float) and val == int(val):
                    val = int(val)
                categories.append(f"{cat_name}_{val}")

        if categories:
            cat_map[image_key] = categories

    wb.close()
    return cat_map


def update_matlab_line(line: str, new_cats: list[str]) -> str:
    """
    Given a funcStruct line and a list of new category strings,
    append them inside the existing [...] bracket.

    Only modifies lines that have a string array bracket [...] as the
    third element of the cell array.
    """
    # Match the bracket list: [...] followed by }; at end of line
    # Pattern: find the last [...] in the line that's inside the cell array
    # We look for: ["...", "..."] before the closing };
    pattern = r'(\[(?:[^\]]*)\])(}\s*;)'
    match = re.search(pattern, line)
    if not match:
        return None  # signal that we couldn't modify this line

    bracket_content = match.group(1)  # e.g., ["Malignant"]
    suffix = match.group(2)           # e.g., };

    # Build the new category entries as quoted strings
    new_entries = ", ".join(f'"{cat}"' for cat in new_cats)

    # Insert before the closing ]
    # Find the position of the closing ] in the bracket
    inner = bracket_content[1:-1].rstrip()  # strip [ and ]
    new_bracket = f"[{inner}, {new_entries}]"

    # Reconstruct the line, preserving everything after the match (e.g., newline)
    start = line[:match.start(1)]
    rest = line[match.end(2):]
    new_line = f"{start}{new_bracket}{suffix}{rest}"
    return new_line


def main():
    dry_run = "--apply" not in sys.argv

    if dry_run:
        print("=== DRY RUN (pass --apply to modify the file) ===\n")

    # Step 1: Build category map from Excel
    print(f"Reading Excel: {EXCEL_FILE}")
    cat_map = build_category_map(EXCEL_FILE)
    print(f"  Found {len(cat_map)} patient entries with categories to add.\n")

    # Step 2: Read MATLAB file
    print(f"Reading MATLAB: {MATLAB_FILE}")
    with open(MATLAB_FILE, "r", encoding="utf-8") as f:
        lines = f.readlines()
    print(f"  {len(lines)} lines read.\n")

    # Step 3: Process each line
    # Build a set of all image keys present in funcStruct lines for matching
    modified_count = 0
    skipped_no_bracket = 0
    matched_keys = set()
    new_lines = []

    for line_num, line in enumerate(lines, 1):
        # Check if this line is a funcStruct assignment (not commented out)
        stripped = line.lstrip()
        if stripped.startswith("%") or not stripped.startswith("funcStruct("):
            new_lines.append(line)
            continue

        # Extract the image key from the line
        key_match = re.search(r"funcStruct\('([^']+)'\)", line)
        if not key_match:
            new_lines.append(line)
            continue

        image_key = key_match.group(1)

        if image_key not in cat_map:
            new_lines.append(line)
            continue

        # We have categories to add for this image
        new_cats = cat_map[image_key]
        matched_keys.add(image_key)

        updated_line = update_matlab_line(line, new_cats)
        if updated_line is None:
            # Line doesn't have bracket format - skip
            skipped_no_bracket += 1
            if dry_run:
                print(f"  SKIP (no bracket) line {line_num}: {line.rstrip()}")
            new_lines.append(line)
            continue

        modified_count += 1
        if dry_run:
            print(f"  Line {line_num}:")
            print(f"    OLD: {line.rstrip()}")
            print(f"    NEW: {updated_line.rstrip()}")
            print()

        new_lines.append(updated_line)

    # Report
    unmatched = set(cat_map.keys()) - matched_keys
    print(f"--- Summary ---")
    print(f"  Lines modified: {modified_count}")
    print(f"  Skipped (no bracket format): {skipped_no_bracket}")
    print(f"  Excel entries with no matching MATLAB line: {len(unmatched)}")
    if unmatched and dry_run:
        for key in sorted(unmatched)[:20]:
            print(f"    {key}")
        if len(unmatched) > 20:
            print(f"    ... and {len(unmatched) - 20} more")

    # Step 4: Write back
    if not dry_run:
        with open(MATLAB_FILE, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
        print(f"\n  File written: {MATLAB_FILE}")
    else:
        print(f"\n  No changes written (dry run).")


if __name__ == "__main__":
    main()
