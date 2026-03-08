# Design: "Create Case" Mode in mammology_app.mlapp

## Problem

Adding new cases requires manually loading an answer key, using the app pointer to find scaled coordinates, running `zone_creator.py` with those coordinates, and pasting the output into `function_list.m`. This is tedious and error-prone.

## Solution

Add a "Create Case" mode directly in the existing MATLAB app that lets the user interactively define elliptical zones on an image, preview the generated code, and auto-append it to `function_list.m`.

## User Flow

1. User clicks a **"Create Case"** button in the app.
2. A dialog prompts for the image number (e.g., `178`) and category (`"Malignant"`, `"Benign"`, etc.).
3. The image (`Images/178_CCMLO_wbenign.jpg`) loads in the existing image display area, scaled identically to quiz mode.
4. User clicks 3 points per ellipse: center, horizontal radius point, vertical radius point. Each ellipse is drawn as an overlay in real-time.
5. A **"Done"** button finishes ellipse entry.
6. A text preview panel shows the generated `funcStruct` entry + MATLAB function code.
7. User clicks **"Save"** to append both to `function_list.m`, or **"Cancel"** to discard.

## Key Details

- **3-click ellipses**: Center click, then a click for horizontal radius (x-distance from center), then a click for vertical radius (y-distance from center).
- **Ellipse overlay**: After each 3-click sequence, draw the resulting ellipse on the image so the user can visually verify coverage.
- **Undo**: An "Undo Last Ellipse" button to remove the most recent ellipse if misclicked.
- **Benign shortcut**: If category is "Benign", skip the clicking — just generate a `funcStruct` entry using the existing `benign()` function.
- **Function naming**: Auto-generated from the image number using the existing spelled-out-words convention (e.g., `178` → `zerooneseveneight_CCMLO_wbenign`).
- **File writing**: Append the `funcStruct` line after the last existing entry, and the function body at the end of the file before the comment block.

## Out of Scope

- No image file management (user still places images manually in `Images/` and `Answers/`).
- No editing of existing cases — this is for new case creation only.
