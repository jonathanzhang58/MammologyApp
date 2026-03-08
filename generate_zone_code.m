function [map_entry, func_body] = generate_zone_code(ellipses, image_number, category)
%GENERATE_ZONE_CODE Generate funcStruct entry and zone detection function.
%   ellipses: Nx4 matrix where each row is [centerX, centerY, radiusX, radiusY]
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
