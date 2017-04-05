function key_values_cell = extract_key_values_from_filenames(filenames_cell, pattern)
% key_values_cell = extract_key_values_from_filenames(filenames_cell, pattern)

% escape the dot character in the pattern: . - > \. to avoid regex
% misinterpreting it.
pattern = strrep(pattern, '.', '\.');

% replace wildcards (*) with random vartiable names which are going to be
% ignored during extraction of values.
firstWildcardId = find(pattern == '*', 1);
randomVariableName = {};
while ~isempty(firstWildcardId)
    randomVariableName{end+1} = ['var_' getUuid];
    pattern = [pattern(1:(firstWildcardId-1)) '[' randomVariableName{end} ']' pattern((firstWildcardId+1):end)];
    firstWildcardId = find(pattern == '*', 1);
end;

%% Extract keys and insert wildcards
key_pointers = regexp(pattern,{'[',']'});
n = length(key_pointers{1});
keys = cell(n,1);
wpattern = [pattern(1:key_pointers{1}(1)-1) '(\w.*)'];
for k=1:n
    keys{k} = pattern(key_pointers{1}(k)+1:key_pointers{2}(k)-1);
    if k>1
        wpattern = [wpattern pattern(key_pointers{2}(k-1)+1:key_pointers{1}(k)-1) '(\w.*)']; %#ok
    end
end
wpattern = [wpattern pattern(key_pointers{2}(k)+1:end)];

%% Match
n = length(filenames_cell);
key_values_cell = cell(size(filenames_cell));
for k=1:n
    c_k = filenames_cell{k};
    [values,match] = regexp(c_k,wpattern,'tokens','match');
    if strcmp(c_k,match)
        
        % ignore dummy variables added as placeholders for wildcards *
        [keysExceptRandomVariables, ids] = setdiff(keys, randomVariableName);
        keyValues = values{1}(ids);
        
        key_values_cell{k} = OrderedMap(keysExceptRandomVariables, keyValues);
    end
end