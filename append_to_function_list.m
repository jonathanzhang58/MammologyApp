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
