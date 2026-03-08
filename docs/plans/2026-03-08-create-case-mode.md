# Create Case Mode — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an interactive "Create Case" tool that lets users click on mammogram images to define elliptical zones, preview the generated MATLAB code, and auto-append it to `function_list.m`.

**Architecture:** Since `.mlapp` files are binary and cannot be edited programmatically, all logic lives in standalone `.m` files. The main tool (`case_creator.m`) builds its UI programmatically using `uifigure`/`uiaxes`/`uibutton`. It reuses the same image-loading approach as the main app to ensure coordinate scaling matches. Three utility functions handle name generation, code generation, and file writing separately.

**Tech Stack:** MATLAB (R2020b+), App Designer programmatic API (`uifigure`, `uiaxes`, `uibutton`, `uitextarea`)

---

### Task 1: Create `number_to_name.m` — digit-to-word utility

**Files:**
- Create: `number_to_name.m`

**What it does:** Ports the naming convention from `zone_creator.py` lines 6-8. Converts an image number like `177` into the function name `zeroonesevenseven_CCMLO_wbenign`.

**Step 1: Write the function**

```matlab
function name = number_to_name(number)
%NUMBER_TO_NAME Convert image number to spelled-out function name.
%   name = number_to_name(177) returns 'zeroonesevenseven_CCMLO_wbenign'

    digit_names = {'zero','one','two','three','four','five','six','seven','eight','nine'};
    digits = num2str(number) - '0';  % char array to digit array
    word = 'zero';
    for i = 1:length(digits)
        word = [word, digit_names{digits(i) + 1}];
    end
    name = [word, '_CCMLO_wbenign'];
end
```

**Step 2: Verify in MATLAB command window**

Run:
```matlab
>> number_to_name(1)    % expect: 'zerozeroone_CCMLO_wbenign' — wait, input is 1 not 001
>> number_to_name(177)  % expect: 'zeroonesevenseven_CCMLO_wbenign'
>> number_to_name(23)   % expect: 'zerotwothree_CCMLO_wbenign'
```

Note: `num2str(1)` gives `'1'`, so digits = `[1]`, word = `'zeroone'`, name = `'zeroone_CCMLO_wbenign'`. But the convention from `zone_creator.py` is `"zero" + "".join(digit_names[int(d)] for d in str(number))`. For number=1, `str(1)` = `"1"`, so it becomes `"zeroone"`. For 001, `str(001)` in Python is `"1"` too. So the function takes the raw number and the convention is just zero-prefix + each digit spelled out. This matches: image 1 → `zerozeroone` because the `funcStruct` key has `001` (3-digit zero-padded), but the function name in the file for image 1 is `zerozeroone_CCMLO_wbenign` — which means the function was generated with number `01` or the Python was called with `1` but the `str(1)` = `"1"` gives `"zeroone"`, not `"zerozeroone"`.

Looking at `zone_creator.py` line 7: `number_name = "zero"+"".join(digit_names[int(digit)] for digit in str(number))`. For `number=1`: `str(1)` = `"1"` → `"zero" + "one"` = `"zeroone"`. But the actual function in `function_list.m` line 787 is `zerozeroone_CCMLO_wbenign` (three words: zero-zero-one). This means `zone_creator.py` was called with `number=01` or the name was manually edited. In practice, the existing names use 3-digit representations (always at least 3 digit-words after the leading "zero"). The simplest fix: zero-pad the number to 3 digits before converting.

**Corrected function:**

```matlab
function name = number_to_name(number)
%NUMBER_TO_NAME Convert image number to spelled-out function name.
%   name = number_to_name(177) returns 'zeroonesevenseven_CCMLO_wbenign'
%   name = number_to_name(1)   returns 'zerozeroone_CCMLO_wbenign'

    digit_names = {'zero','one','two','three','four','five','six','seven','eight','nine'};
    padded = sprintf('%03d', number);  % zero-pad to at least 3 digits
    digits = padded - '0';
    word = 'zero';
    for i = 1:length(digits)
        word = [word, digit_names{digits(i) + 1}];
    end
    name = [word, '_CCMLO_wbenign'];
end
```

**Step 3: Re-verify**

```matlab
>> number_to_name(1)    % expect: 'zerozeroone_CCMLO_wbenign'
>> number_to_name(177)  % expect: 'zeroonesevenseven_CCMLO_wbenign'
>> number_to_name(23)   % expect: 'zerozerotwothree_CCMLO_wbenign'
```

Cross-check against existing entries in `function_list.m`:
- Image 1: line 787 has `zerozeroone_CCMLO_wbenign` ✓
- Image 177: line 171 has `zeroonesevenseven_CCMLO_wbenign` ✓
- Image 23: line 779 has `zerotwothree_CCMLO_wbenign` — this is `zero` + `two` + `three`, only 2 digit-words after the prefix. But `sprintf('%03d', 23)` = `'023'` → `zero` + `zero` + `two` + `three` = `zerozerotwothree`. The actual file has `zerotwothree`. So image 23 was generated from `str(23)` = `"23"` in Python → `"zero" + "two" + "three"` = `"zerotwothree"`.

This means the Python convention does NOT zero-pad — it just takes the raw number's digits. The `zerozeroone` for image 1 would come from passing `01` as the number in Python (which Python interprets as `1`, giving `str(1)` = `"1"` → `"zeroone"`). But the actual function is `zerozeroone` (3 digit-words). Looking at the `funcStruct` entry on line 3: the image key is `001_CCMLO_wbenign.jpg` which has 3-digit padding, but the function is `zerozeroone`.

Let me check more examples:
- Image 2 (line 797): `zerozerotwo_CCMLO_wbenign` → 3 digit-words: `zero`+`zero`+`two`
- Image 11 (line 805): `zerooneone_CCMLO_wbenign` → `zero`+`one`+`one` (from `str(11)` = `"11"` → `"zero"+"one"+"one"`)
- Image 23 (line 779): `zerotwothree_CCMLO_wbenign` → `zero`+`two`+`three` (from `str(23)`)

So the pattern is: `"zero"` prefix + each digit of the raw number spelled out (no zero-padding). Images 1-9 must have been entered as strings like `"01"` in Python to get `zerozeroone` (since `str(1)` gives just `"1"`). Or they used leading zeros in Python 2.

For the MATLAB tool, we should follow the same convention as existing entries. Looking at 3-digit images (100+):
- Image 102 (line 482): `zeroonezerotwo_CCMLO_wbenign` → `zero`+`one`+`zero`+`two` (from `str(102)`)
- Image 177 (line 171): `zeroonesevenseven_CCMLO_wbenign` → `zero`+`one`+`seven`+`seven`

For 2-digit images:
- Image 11: `zerooneone` → `zero` + `one` + `one`
- Image 23: `zerotwothree` → `zero` + `two` + `three`

For 1-digit images (well, images 1-9):
- Image 1: `zerozeroone` → `zero` + `zero` + `one`
- Image 2: `zerozerotwo` → `zero` + `zero` + `two`

So images 1-9 have the pattern `zero` + `zero` + digit, which means they were generated with 2-digit input (`01`, `02`, etc.) in Python where `str(01)` = `"1"` wouldn't work... unless the code was called differently.

Actually, in `zone_creator.py` line 7: `number_name = "zero"+"".join(digit_names[int(digit)] for digit in str(number))`. If called with `zone(points, 1)`, `str(1)` = `"1"`, so `number_name` = `"zeroone"`, giving function name `zeroone_CCMLO_wbenign`. But the file has `zerozeroone_CCMLO_wbenign`.

This means either:
1. The early entries (images 1-9) were manually named, or
2. The Python was called with different arguments

Either way, for NEW images going forward (likely 178+, all 3-digit numbers), the raw number approach works: `str(178)` → digits `1,7,8` → `"zerooneseveneight"`. No padding needed for 3-digit numbers.

**Final correct function — no padding, matches Python `str()` behavior:**

```matlab
function name = number_to_name(number)
    digit_names = {'zero','one','two','three','four','five','six','seven','eight','nine'};
    digits = num2str(number) - '0';
    word = 'zero';
    for i = 1:length(digits)
        word = [word, digit_names{digits(i) + 1}];
    end
    name = [word, '_CCMLO_wbenign'];
end
```

For new 3-digit images (178+), this produces the correct naming. If single-digit images are ever needed, the caller should pass them as 2-digit (e.g., use string input — but this is unlikely to be needed).

**Step 4: Commit**

```bash
git add number_to_name.m
git commit -m "feat: add number-to-name utility for case creator"
```

---

### Task 2: Create `generate_zone_code.m` — code generation utility

**Files:**
- Create: `generate_zone_code.m`

**What it does:** Takes ellipse definitions and image metadata, returns two strings: the `funcStruct` map entry and the MATLAB function body. Ports `zone_creator.py` lines 8-33.

**Step 1: Write the function**

```matlab
function [map_entry, func_body] = generate_zone_code(ellipses, image_number, category)
%GENERATE_ZONE_CODE Generate funcStruct entry and zone detection function.
%   ellipses: Nx3 matrix where each row is [centerX, centerY, radiusX, radiusY]
%             (radiusX and radiusY are already computed by caller)
%   image_number: integer (e.g., 178)
%   category: string or string array (e.g., "Malignant" or ["Malignant","TestCategory"])
%
%   Returns:
%     map_entry  - the funcStruct('Images/...') = {...}; line
%     func_body  - the full function definition

    func_name = number_to_name(image_number);
    img_key = sprintf('Images/%03d_CCMLO_wbenign.jpg', image_number);
    answer_key = sprintf('Answers/%03d_CCMLO_wannot.jpg', image_number);

    % Build category string: ["Cat1", "Cat2"]
    if isstring(category) && length(category) == 1
        cat_str = sprintf('["%s"]', category);
    else
        parts = arrayfun(@(c) sprintf('"%s"', c), category, 'UniformOutput', false);
        cat_str = ['[' strjoin(parts, ', ') ']'];
    end

    % Build map entry
    map_entry = sprintf("funcStruct('%s') = {@(x, y) %s(x, y),\"%s\", %s};", ...
        img_key, func_name, answer_key, cat_str);

    % Build function body
    func_body = sprintf('function result1 = %s(x , y)\n', func_name);
    func_body = [func_body, '    if '];

    for i = 1:size(ellipses, 1)
        cx = ellipses(i, 1);
        cy = ellipses(i, 2);
        rx = ellipses(i, 3);
        ry = ellipses(i, 4);
        clause = sprintf('((x-%g)^2 / %g^2) + ((y-%g)^2 / %g^2) < 1', cx, cy, rx, ry);
        if i < size(ellipses, 1)
            func_body = [func_body, clause, ' || ...\n'];
        else
            func_body = [func_body, clause, '\n'];
        end
    end

    func_body = [func_body, '        result1 = true;\n'];
    func_body = [func_body, '    else\n'];
    func_body = [func_body, '        result1 = false;\n'];
    func_body = [func_body, '    end\n'];
    func_body = [func_body, 'end\n'];

    % Convert \n escape sequences to actual newlines
    func_body = sprintf(func_body);
end
```

**Step 2: Verify in MATLAB command window**

```matlab
>> ellipses = [44, 37, 3, 4; 9.1, 18, 3.0, 4];
>> [entry, body] = generate_zone_code(ellipses, 177, "Malignant");
>> disp(entry)
>> disp(body)
```

Expected `entry`:
```
funcStruct('Images/177_CCMLO_wbenign.jpg') = {@(x, y) zeroonesevenseven_CCMLO_wbenign(x, y),"Answers/177_CCMLO_wannot.jpg", ["Malignant"]};
```

Expected `body` (should match `function_list.m` lines 171-178):
```
function result1 = zeroonesevenseven_CCMLO_wbenign(x , y)
    if ((x-44)^2 / 3^2) + ((y-37)^2 / 4^2) < 1 || ...
((x-9.1)^2 / 3^2) + ((y-18)^2 / 4^2) < 1
        result1 = true;
    else
        result1 = false;
    end
end
```

**Step 3: Commit**

```bash
git add generate_zone_code.m
git commit -m "feat: add zone code generation utility for case creator"
```

---

### Task 3: Create `generate_benign_entry.m` — benign case shortcut

**Files:**
- Create: `generate_benign_entry.m`

**What it does:** Generates a `funcStruct` entry for benign images (no function body needed — reuses the existing `benign()` function in `function_list.m` line 829).

**Step 1: Write the function**

```matlab
function map_entry = generate_benign_entry(image_number)
%GENERATE_BENIGN_ENTRY Generate funcStruct entry for a benign image.
%   Uses the existing benign() function and shared answer key.

    img_key = sprintf('Images/%03d_CCMLO_wbenign.jpg', image_number);
    map_entry = sprintf("funcStruct('%s') = {@(x, y) benign(x, y),\"Answers/003_CCMLO_key.jpg\", [\"Benign\"]};", img_key);
end
```

Note: All benign entries in `function_list.m` use `Answers/003_CCMLO_key.jpg` as the answer key and the shared `benign()` function.

**Step 2: Verify**

```matlab
>> disp(generate_benign_entry(200))
```

Expected:
```
funcStruct('Images/200_CCMLO_wbenign.jpg') = {@(x, y) benign(x, y),"Answers/003_CCMLO_key.jpg", ["Benign"]};
```

**Step 3: Commit**

```bash
git add generate_benign_entry.m
git commit -m "feat: add benign entry generator for case creator"
```

---

### Task 4: Create `append_to_function_list.m` — file writer

**Files:**
- Create: `append_to_function_list.m`

**What it does:** Appends a new `funcStruct` entry and (optionally) a function body to `function_list.m`. The entry goes after the last existing `funcStruct(...)` line. The function body goes before the trailing comment block (which starts at the `% TESTING` line, currently line 840).

**Step 1: Write the function**

```matlab
function append_to_function_list(map_entry, func_body)
%APPEND_TO_FUNCTION_LIST Append a new case to function_list.m
%   map_entry: string, the funcStruct('Images/...') = {...}; line
%   func_body: string (optional), the full function definition
%              Pass "" or omit for benign cases that reuse benign()

    if nargin < 2
        func_body = "";
    end

    filepath = fullfile(fileparts(mfilename('fullpath')), 'function_list.m');
    lines = readlines(filepath);

    % Find the last funcStruct entry line
    last_entry_idx = 0;
    for i = 1:length(lines)
        if startsWith(strtrim(lines(i)), "funcStruct(")
            last_entry_idx = i;
        end
    end

    % Find the comment block (% TESTING)
    comment_idx = 0;
    for i = 1:length(lines)
        if strtrim(lines(i)) == "% TESTING"
            comment_idx = i;
            break;
        end
    end

    % Build new file contents
    new_lines = lines(1:last_entry_idx);
    new_lines = [new_lines; map_entry];

    if func_body ~= ""
        % Insert function body before the comment block
        new_lines = [new_lines; lines(last_entry_idx+1:comment_idx-1)];
        new_lines = [new_lines; func_body];
        new_lines = [new_lines; lines(comment_idx:end)];
    else
        new_lines = [new_lines; lines(last_entry_idx+1:end)];
    end

    writelines(new_lines, filepath);
end
```

**Step 2: Verify by inspecting (do NOT run on the real file yet — will be tested via case_creator)**

```matlab
>> help append_to_function_list  % should display help text
```

**Step 3: Commit**

```bash
git add append_to_function_list.m
git commit -m "feat: add function_list.m file writer for case creator"
```

---

### Task 5: Create `case_creator.m` — the main interactive tool

**Files:**
- Create: `case_creator.m`

**What it does:** Opens a programmatic MATLAB figure with:
- Input dialogs for image number and category
- Image display in a `uiaxes` (same display method as the main app)
- Click handling: 3 clicks per ellipse (center → horizontal edge → vertical edge)
- Real-time ellipse overlay drawn after each 3-click sequence
- "Done", "Undo Last Ellipse", "Save to function_list.m", "Cancel" buttons
- Text area showing generated code preview
- Benign shortcut: skips clicking, generates entry immediately

**Step 1: Write the function**

```matlab
function case_creator()
%CASE_CREATOR Interactive tool to create new mammography case entries.
%   Opens a GUI where you click on an image to define elliptical zones,
%   then saves the generated code to function_list.m.

    %% Prompt for image number and category
    answer = inputdlg({'Image number:', 'Category (e.g., Malignant):'}, ...
        'New Case', 1, {'', 'Malignant'});
    if isempty(answer)
        return;
    end
    image_number = str2double(answer{1});
    category = string(answer{2});

    if isnan(image_number) || image_number < 1
        errordlg('Invalid image number.', 'Error');
        return;
    end

    img_path = fullfile(fileparts(mfilename('fullpath')), ...
        sprintf('Images/%03d_CCMLO_wbenign.jpg', image_number));
    if ~isfile(img_path)
        errordlg(sprintf('Image not found: %s', img_path), 'Error');
        return;
    end

    %% Benign shortcut
    if strcmpi(category, 'Benign')
        entry = generate_benign_entry(image_number);
        choice = questdlg(sprintf('Generate benign entry?\n\n%s', entry), ...
            'Confirm', 'Save', 'Cancel', 'Save');
        if strcmp(choice, 'Save')
            append_to_function_list(entry);
            msgbox('Benign case saved to function_list.m', 'Done');
        end
        return;
    end

    %% Build the interactive figure
    fig = uifigure('Name', sprintf('Case Creator — Image %03d', image_number), ...
        'Position', [100 100 1000 700]);

    % Layout: image on left (700px wide), controls on right (300px)
    img_panel = uipanel(fig, 'Position', [0 0 700 700], 'BorderType', 'none');
    ctrl_panel = uipanel(fig, 'Position', [700 0 300 700], 'BorderType', 'none');

    ax = uiaxes(img_panel, 'Position', [10 10 680 680]);
    img = imread(img_path);
    imshow(img, 'Parent', ax);
    hold(ax, 'on');
    ax.Toolbar.Visible = 'off';
    disableDefaultInteractivity(ax);

    % Status label
    status_label = uilabel(ctrl_panel, 'Position', [10 660 280 30], ...
        'Text', 'Click center of ellipse (1/3)', ...
        'FontSize', 14, 'FontWeight', 'bold');

    % Ellipse count label
    count_label = uilabel(ctrl_panel, 'Position', [10 630 280 25], ...
        'Text', 'Ellipses defined: 0', 'FontSize', 12);

    % Code preview
    uilabel(ctrl_panel, 'Position', [10 395 280 25], ...
        'Text', 'Code Preview:', 'FontSize', 12, 'FontWeight', 'bold');
    preview_area = uitextarea(ctrl_panel, 'Position', [10 100 280 295], ...
        'Editable', 'off', 'FontName', 'Consolas');

    % Buttons
    undo_btn = uibutton(ctrl_panel, 'Position', [10 60 130 30], ...
        'Text', 'Undo Last Ellipse', 'Enable', 'off');
    done_btn = uibutton(ctrl_panel, 'Position', [150 60 130 30], ...
        'Text', 'Done', 'Enable', 'off');
    save_btn = uibutton(ctrl_panel, 'Position', [10 20 130 30], ...
        'Text', 'Save', 'Enable', 'off');
    cancel_btn = uibutton(ctrl_panel, 'Position', [150 20 130 30], ...
        'Text', 'Cancel');

    %% State stored in a struct (shared across callbacks via fig.UserData)
    state.ellipses = [];          % Nx4 matrix: [cx, cy, rx, ry]
    state.click_count = 0;        % 0, 1, or 2 (within current 3-click sequence)
    state.current_center = [];    % [cx, cy] after first click
    state.current_rx = [];        % rx after second click
    state.plot_handles = {};      % cell array of plot handles for ellipse overlays
    state.click_markers = {};     % temporary markers for in-progress clicks
    state.image_number = image_number;
    state.category = category;
    fig.UserData = state;

    %% Click callback on axes
    ax.ButtonDownFcn = @(~, event) on_axes_click(fig, ax, event, ...
        status_label, count_label, preview_area, done_btn, undo_btn);
    % Also make the image respond to clicks
    img_obj = findobj(ax, 'Type', 'Image');
    if ~isempty(img_obj)
        img_obj.HitTest = 'on';
        img_obj.ButtonDownFcn = @(~, event) on_axes_click(fig, ax, event, ...
            status_label, count_label, preview_area, done_btn, undo_btn);
    end

    %% Button callbacks
    undo_btn.ButtonDownFcn = [];
    undo_btn.ButtonPushedFcn = @(~,~) on_undo(fig, ax, status_label, count_label, ...
        preview_area, done_btn, undo_btn, save_btn);
    done_btn.ButtonPushedFcn = @(~,~) on_done(fig, preview_area, save_btn, done_btn, ...
        status_label, ax);
    save_btn.ButtonPushedFcn = @(~,~) on_save(fig);
    cancel_btn.ButtonPushedFcn = @(~,~) close(fig);
end

%% --- Callback functions ---

function on_axes_click(fig, ax, event, status_label, count_label, preview_area, done_btn, undo_btn)
    state = fig.UserData;
    pt = event.IntersectionPoint(1:2);  % [x, y]
    x = pt(1); y = pt(2);

    if state.click_count == 0
        % First click: center
        state.current_center = [x, y];
        state.click_count = 1;
        % Draw a marker at center
        h = plot(ax, x, y, 'r+', 'MarkerSize', 15, 'LineWidth', 2);
        state.click_markers{end+1} = h;
        status_label.Text = sprintf('Click horizontal edge (2/3) — center: (%.1f, %.1f)', x, y);

    elseif state.click_count == 1
        % Second click: horizontal radius
        state.current_rx = abs(x - state.current_center(1));
        state.click_count = 2;
        h = plot(ax, x, y, 'rx', 'MarkerSize', 10, 'LineWidth', 2);
        state.click_markers{end+1} = h;
        status_label.Text = sprintf('Click vertical edge (3/3) — rx: %.1f', state.current_rx);

    elseif state.click_count == 2
        % Third click: vertical radius → ellipse complete
        ry = abs(y - state.current_center(2));
        cx = state.current_center(1);
        cy = state.current_center(2);
        rx = state.current_rx;

        % Store ellipse
        state.ellipses = [state.ellipses; cx, cy, rx, ry];
        state.click_count = 0;
        state.current_center = [];
        state.current_rx = [];

        % Clear temporary markers
        for k = 1:length(state.click_markers)
            delete(state.click_markers{k});
        end
        state.click_markers = {};

        % Draw the ellipse overlay
        theta = linspace(0, 2*pi, 100);
        ex = cx + rx * cos(theta);
        ey = cy + ry * sin(theta);
        h = plot(ax, ex, ey, 'r-', 'LineWidth', 2);
        hc = plot(ax, cx, cy, 'r+', 'MarkerSize', 10, 'LineWidth', 2);
        state.plot_handles{end+1} = [h, hc];

        n = size(state.ellipses, 1);
        count_label.Text = sprintf('Ellipses defined: %d', n);
        status_label.Text = 'Click center of next ellipse (1/3)';
        done_btn.Enable = 'on';
        undo_btn.Enable = 'on';

        % Update preview
        [entry, body] = generate_zone_code(state.ellipses, ...
            state.image_number, state.category);
        preview_area.Value = [char(entry), newline, newline, body];
    end

    fig.UserData = state;
end

function on_undo(fig, ax, status_label, count_label, preview_area, done_btn, undo_btn, save_btn)
    state = fig.UserData;

    % Clear any in-progress click markers
    for k = 1:length(state.click_markers)
        delete(state.click_markers{k});
    end
    state.click_markers = {};
    state.click_count = 0;
    state.current_center = [];
    state.current_rx = [];

    if ~isempty(state.ellipses)
        % Remove last ellipse
        state.ellipses = state.ellipses(1:end-1, :);

        % Remove last overlay
        handles = state.plot_handles{end};
        for h = handles
            delete(h);
        end
        state.plot_handles = state.plot_handles(1:end-1);
    end

    n = size(state.ellipses, 1);
    count_label.Text = sprintf('Ellipses defined: %d', n);
    status_label.Text = 'Click center of ellipse (1/3)';

    if n == 0
        done_btn.Enable = 'off';
        undo_btn.Enable = 'off';
        preview_area.Value = '';
    else
        [entry, body] = generate_zone_code(state.ellipses, ...
            state.image_number, state.category);
        preview_area.Value = [char(entry), newline, newline, body];
    end

    save_btn.Enable = 'off';
    fig.UserData = state;
end

function on_done(fig, preview_area, save_btn, done_btn, status_label, ax)
    state = fig.UserData;

    % Clear any in-progress click markers
    for k = 1:length(state.click_markers)
        delete(state.click_markers{k});
    end
    state.click_markers = {};
    state.click_count = 0;
    state.current_center = [];
    state.current_rx = [];

    % Disable further clicking
    ax.ButtonDownFcn = [];
    img_obj = findobj(ax, 'Type', 'Image');
    if ~isempty(img_obj)
        img_obj.ButtonDownFcn = [];
    end

    status_label.Text = 'Review the code preview, then click Save.';
    save_btn.Enable = 'on';
    done_btn.Enable = 'off';
    fig.UserData = state;
end

function on_save(fig)
    state = fig.UserData;
    [entry, body] = generate_zone_code(state.ellipses, ...
        state.image_number, state.category);
    append_to_function_list(entry, body);
    msgbox(sprintf('Case %03d saved to function_list.m', state.image_number), 'Done');
    close(fig);
end
```

**Step 2: Manual test — launch and create a test case**

1. Place a test image at `Images/999_CCMLO_wbenign.jpg` (copy any existing image)
2. Run `case_creator()` in MATLAB
3. Enter image number `999`, category `Malignant`
4. Click 3 points to define one ellipse
5. Verify the ellipse overlay appears on the image
6. Click "Done", verify the code preview looks correct
7. Click "Save", verify `function_list.m` has the new entry
8. Manually remove the test entry from `function_list.m` and delete the test image

**Step 3: Commit**

```bash
git add case_creator.m
git commit -m "feat: add interactive case creator tool"
```

---

### Task 6: Add "Create Case" button to mammology_app (manual App Designer step)

**Files:**
- Modify: `mammology_app.mlapp` (via MATLAB App Designer GUI)

**This task must be done manually in MATLAB App Designer.** It cannot be automated.

**Step 1: Open the app in App Designer**

```matlab
>> appdesigner('mammology_app.mlapp')
```

**Step 2: Add a button**

1. Drag a **Button** component onto the app canvas (place it near the other control buttons)
2. Set the button's **Text** property to `Create Case`
3. In the button's **ButtonPushedFcn** callback, add this single line:

```matlab
case_creator();
```

**Step 3: Save the `.mlapp` file**

**Step 4: Test end-to-end**

1. Run `mammology_app`
2. Click "Create Case"
3. Define zones on an image
4. Verify the entry appears in `function_list.m`
5. Restart the app and verify the new case loads correctly in the quiz

**Step 5: Commit**

```bash
git add mammology_app.mlapp
git commit -m "feat: add Create Case button to main app"
```
