
funcStruct = containers.Map();
funcStruct('Images/001_CCMLO_wbenign.jpg') = {@(x, y) zerozeroone_CCMLO_wbenign(x, y),"Answers/001_CCMLO_key.jpg", "category1 (image 1)"};
funcStruct('Images/002_CCMLO_wbenign.jpg') = {@(x, y) zerozerotwo_CCMLO_wbenign(x, y),"Answers/002_CCMLO_key.jpg", "category2 (image 2)"};
funcStruct('Images/003_CCMLO_wbenign.jpg') = {@(x, y) zerozerothree_CCMLO_wbenign(x, y),"Answers/003_CCMLO_key.jpg", "category3 (image 3-4)"};
funcStruct('Images/testimage.jpg') = {@(x, y) test(x, y),"Answers/testanswer.jpg", "category3 (image 3-4)"};

% Define the function with conditional logic
function result1 = zerozeroone_CCMLO_wbenign(x, y)
    if (x-15.7784)^2 + (y-30.5892)^2 < (0.16910000000000025+1)^2 || ...
       (x-20.7937)^2 + (y-38.0298)^2 < (1.465200000000003+1)^2 || ...
       (x-55.0554)^2 + (y-34.1717)^2 < (0.7890000000000015+1)^2 || ...
       (x-55.0554)^2 + (y-47.5373)^2 < (5)^2 
        result1 = true;
    else
        result1 = false;
    end
end
function result1 = zerozerotwo_CCMLO_wbenign(x, y)
    if (x-9.4)^2 + (y-26)^2 < 1.4000000000000004^2 || ...
        (x-46)^2 + (y-37)^2 < 2^2
        result1 = true;
    else
        result1 = false;
    end
end
function result1 = zerozerothree_CCMLO_wbenign(x, y)
    if x>24 && x<37 && y<63 && y>53
        result1 = true;
    else
        result1 = false;
    end
end
function result1 = test(x, y)
    if (x-55)^2 + (y-36)^2 < 3^2
        result1 = true;
    else
        result1 = false;
    end
end


% TESTING
% Display the contents of the map
% disp(x)
% 
% % Perform operation on the given image key with specific coordinates
% result = x('001_CCMLO_wbenign.jpg')
% disp(result)
% result(1,1)

% OBSELETE CODE
% Define a struct array with a function handle that includes conditional logic
% funcStruct(1).name = '001_CCMLO_wbenign.jpg';
% funcStruct(1).operation = @(x, y) ifElseFunction(x, y);
% Create a containers.Map to map the image filename to a function handle
% Example usage: Calling the function
% result1 = funcStruct(1).operation(5, 3);  % "5 is greater than 3"
% result2 = funcStruct(1).operation(2, 7);  % "2 is less than 7"
% result3 = funcStruct(1).operation(4, 4);  % "4 is equal to 4"
% 
% % Display the results
% disp(result1);
% disp(result2);
% disp(result3);
