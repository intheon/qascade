function s = map_to_struc(map)
% s = map_to_struc(map)
% converts a containers.Map object to a structure.

keys = map.keys;
values = map.values;

for i=1:length(keys)
    if isa(values{i}, 'containers.Map')
        values{i} = map_to_struc(values{i});
    end;
    
    if ~isempty(values{i})
        values{i} = map_array_to_struct_array(values{i});
    end;
    
    s.(matlab.lang.makeValidName(keys{i})) = values{i};
end;