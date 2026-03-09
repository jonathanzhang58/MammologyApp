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

    %% Click callback on image only (not axes — avoids event conflicts)
    img_obj = findobj(ax, 'Type', 'Image');
    if ~isempty(img_obj)
        img_obj.HitTest = 'on';
        img_obj.ButtonDownFcn = @(~, event) on_axes_click(fig, ax, event, ...
            status_label, count_label, preview_area, done_btn, undo_btn);
    end

    %% Button callbacks
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
        fig.UserData = state;  % save before UI updates (plot can trigger drawnow)
        h = plot(ax, x, y, 'r+', 'MarkerSize', 15, 'LineWidth', 2, 'HitTest', 'off');
        state.click_markers{end+1} = h;
        status_label.Text = sprintf('Click horizontal edge (2/3) — center: (%.1f, %.1f)', x, y);

    elseif state.click_count == 1
        % Second click: horizontal radius
        state.current_rx = abs(x - state.current_center(1));
        state.click_count = 2;
        fig.UserData = state;  % save before UI updates
        h = plot(ax, x, y, 'rx', 'MarkerSize', 10, 'LineWidth', 2, 'HitTest', 'off');
        state.click_markers{end+1} = h;
        status_label.Text = sprintf('Click vertical edge (3/3) — rx: %.1f', state.current_rx);

    elseif state.click_count == 2
        % Third click: vertical radius -> ellipse complete
        ry = abs(y - state.current_center(2));
        cx = state.current_center(1);
        cy = state.current_center(2);
        rx = state.current_rx;

        % Store ellipse and reset click state
        state.ellipses = [state.ellipses; cx, cy, rx, ry];
        state.click_count = 0;
        state.current_center = [];
        state.current_rx = [];
        fig.UserData = state;  % save IMMEDIATELY before any UI/plot calls

        % Clear temporary markers
        for k = 1:length(state.click_markers)
            delete(state.click_markers{k});
        end
        state.click_markers = {};

        % Draw the ellipse overlay (HitTest off so clicks pass through to image)
        theta = linspace(0, 2*pi, 100);
        ex = cx + rx * cos(theta);
        ey = cy + ry * sin(theta);
        h = plot(ax, ex, ey, 'r-', 'LineWidth', 2, 'HitTest', 'off');
        hc = plot(ax, cx, cy, 'r+', 'MarkerSize', 10, 'LineWidth', 2, 'HitTest', 'off');
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
