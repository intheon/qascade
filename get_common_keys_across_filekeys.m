function commonKeys = get_common_keys_across_filekeys(fileKeys)

keys = fileKeys.keys;
commonKeys = {};
for i=1:length(keys)    
    if isa(fileKeys(keys{i}), 'containers.Map') 
        particuarFileMap = fileKeys(keys{i});
        if i==1
             commonKeys = particuarFileMap.keys;
        else
             commonKeys = intersect(commonKeys, particuarFileMap.keys);
        end;       
    end;
end;