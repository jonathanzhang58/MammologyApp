function name = number_to_name(number)
%NUMBER_TO_NAME Convert image number to spelled-out function name.
%   name = number_to_name(177) returns 'zeroonesevenseven_CCMLO_wbenign'
%   name = number_to_name(1)   returns 'zeroone_CCMLO_wbenign'

    digit_names = {'zero','one','two','three','four','five','six','seven','eight','nine'};
    digits = num2str(number) - '0';
    word = 'zero';
    for i = 1:length(digits)
        word = [word, digit_names{digits(i) + 1}];
    end
    name = [word, '_CCMLO_wbenign'];
end
