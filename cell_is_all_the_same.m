function itIs = cell_is_all_the_same(inputCell)
% returns true only if all the items inside the cell are the same. 
% Works for any type of object.

itIs = true;
for i=1:(length(inputCell)-1)
    if ~isequal(inputCell{i},inputCell{i+1})
        itIs = false;
        break;
    end;
end;