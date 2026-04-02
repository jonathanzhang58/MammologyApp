function map_entry = generate_benign_entry(image_number)
%GENERATE_BENIGN_ENTRY Generate funcStruct entry for a benign image.
%   Uses the existing benign() function and shared answer key.

    img_key = sprintf('Images/%03d_CCMLO_wbenign.jpg', image_number);
    map_entry = sprintf("funcStruct('%s') = {@(x, y) benign(x, y),\"Answers/003_CCMLO_key.jpg\", [\"Benign\"]};", img_key);
end
