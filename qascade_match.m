function cell_out = qascade_match(cell_in, pattern)
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
n = length(cell_in);
cell_out = cell(size(cell_in));
for k=1:n
    c_k = cell_in{k};
    [values,match] = regexp(c_k,wpattern,'tokens','match');
    if strcmp(c_k,match)
        cell_out{k} = containers.Map(keys, values{1});
    end
end