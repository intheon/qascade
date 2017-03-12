function [files, values] = qascade_find(fileKeyValues, query)
% [files, values] = qascade_find(fileKeyValues, query)
%
% input:
%    'query' is either a string or a cell array of strings. Each cell contains a field key name, e.g.
%    'samplingRate', or the address of a nested field, e.g. 'subject.name'
% output:
%    'files' is a cell array with the names of files that had query keys (and matched query values,
%            if existed) 
%    'values' is a cell array contaiing the inner most values for each que, e.g. 'a.b.c' returns the value of c in field b of variable a
%             if a nested field is a sequence (array), all items in the array must have the query
%             field. In this case, the returned values will be a cell, one for each element of that
%             array.
if ~iscell(query)
    query = {query};
end;

query = strrep(query, '==', '=');

queryVariables = query; % list of variables in queries, these cab ne of form a.b.c to indicate nested variables (fields).

fileNames = fileKeyValues.keys;
hasVariableMask = false(length(fileNames), length(queryVariables));
valueForvariable = cell(length(fileNames), length(queryVariables));
for i=1:length(fileNames)
    for j=1:length(queryVariables)
         [valueForvariable{i,j}, hasVariableMask(i,j)] = getValueForQuery(fileKeyValues(fileNames{i}), queryVariables{j});
    end;
end;

selectedMask = all(hasVariableMask, 2);
files = fileNames(selectedMask); % all variables level must be present
values = valueForvariable(selectedMask,:);
end

function [value, valueFound] = getValueForQuery(map, query)
 if any(query == '.')
     parts = strsplit(query, '.');
     [value1, valueFound1] = getValueForQuery(map, parts{1});
     if valueFound1
         if length(value1) == 1
         [value, valueFound] = getValueForQuery(value1, strjoin_adjoiner_first('.', parts(2:end)));
         else
             valueFound = true;
             for i=1:length(value1)
                 [value{i}, valueFoundForIndex] = getValueForQuery(value1{i}, strjoin_adjoiner_first('.', parts(2:end)));
                 valueFound = valueFound && valueFoundForIndex;
             end;
         end;
     else
         valueFound = false;
         value = [];
     end;
 else
     valueFound = isKey(map, query);
     if valueFound
         value = map(query);
     else
         value = [];
     end;
 end;
end