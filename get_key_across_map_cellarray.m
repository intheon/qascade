function keyValues = get_key_across_map_cellarray(queryKey, mapCellArray)
% keyValues = get_key_across_map_cellarray(queryKey, mapCellArray)
% get the values for a given key (string) across all itemsin a cell array of container.Map obejcts.
% 
% keyValues is a cell array with empty values for files without the 'queryKey'
% and the value of 'queryKey' for cell indices that have it as a key.

keyValues = cell(length(mapCellArray), 1);
for i=1:length(mapCellArray)
    if isa(mapCellArray{i}, 'containers.Map') && isKey(mapCellArray{i}, queryKey)
        t = mapCellArray{i};
        keyValues{i} = t(queryKey);
    end;
end;