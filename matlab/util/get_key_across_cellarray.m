function keyValues = get_key_across_cellarray(queryKey, mapCellArray)
% keyValues = get_key_across_cellarray(queryKey, mapCellArray)
% get the values for a given key (string) across all items in a cell array of structures or container.Map obejects.
% 
% keyValues is a cell array with empty values for files without the 'queryKey'
% and the value of 'queryKey' for cell indices that have it as a key.

keyValues = cell(length(mapCellArray), 1);
for i=1:length(mapCellArray)
    if isa(mapCellArray{i}, 'containers.Map') && isKey(mapCellArray{i}, queryKey)
        t = mapCellArray{i};
        keyValues{i} = t(queryKey);
    elseif isstruct(mapCellArray{i}) && isfield(mapCellArray{i}, queryKey)
        keyValues{i} = mapCellArray{i}.(queryKey);
    end;
end;