function structArray = map_array_to_struct_array(mapArray)

structArray = mapArray;

if iscell(mapArray) && all(cellfun(@(x) isa(x, 'containers.Map'), mapArray))
    strucCell = cell(length(mapArray));
    allFieldNamesAreTheSame = true;
    for i=1:length(mapArray)
        strucCell{i} = map_to_struc(mapArray{i});
        if i==1
            fieldNames = fieldnames(strucCell{i});
        else
            allFieldNamesAreTheSame = allFieldNamesAreTheSame && isequal(fieldnames(strucCell{i}), fieldNames);
        end;
    end;
    
    if allFieldNamesAreTheSame
        clear structArray
        for i=1:length(strucCell)
            structArray(i) = strucCell{i};
        end;
    else
        return;
    end
    
end;
