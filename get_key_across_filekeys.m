function keyValues = get_key_across_filekeys(queryKey, fileKeys)
% keyValues = get_key_across_filekeys(queryKey, fileKeys)
% get the values for a given key (string) across all items from a map of (filename, [Map of keey,
% values]).
% 
% keyValues is a cell array with empty values for files without the 'queryKey'
% and the value of 'queryKey' for files that have it as a key.

keys = fileKeys.keys;
keyValues = cell(length(keys), 1);
for i=1:length(keys)
    if isa(fileKeys(keys{i}), 'containers.Map') && isKey(fileKeys(keys{i}), queryKey)
        t = fileKeys(keys{i});
        keyValues{i} = t(queryKey);
    end;
end;