function [foundFiles, foundValues, allFileNames, hasVariableMask] = qascade_find(fileKeyValues, query)
% [foundFiles, foundValues, allFileNames, hasVariableMask] = qascade_find(fileKeyValues, query)
%
% input:
%    'fileKeyValues': is an output from qascade_read() function.
%    'query' is either a string or a cell array of strings. Each cell contains a field key name, e.g.
%    'samplingRate', or the address of a nested field, e.g. 'subject.name'
% output:
%    'foundFiles' is a cell array with the names of files that had query keys (and matched query values,
%            if existed) 
%    'foundValues' is a cell array contaiing the inner most values for each query, e.g. 'a.b.c' returns the value of c in field b of variable a
%             if a nested field is a sequence (array), all items in the array must have the query
%             field. In this case, the returned values will be a cell, one for each element of that
%             array.
%
%    'allFileNames': a cell array containing all the file names conatined in fileKeyValues variable.
%    'hasVariableMask' is a boolean array the size of input 'fileKeyValues' on the first dimension and
%             the size of 'query' on the second dimension. It is true for indices where the variable
%             is found and false otherwise.
%
% Copyright 2018 © Intheon

if ~iscell(query)
    query = {query};
end;

query = strrep(query, '==', '=');

queryVariables = query; % list of variables in queries, these cab ne of form a.b.c to indicate nested variables (fields).

allFileNames = fileKeyValues.keys;
hasVariableMask = false(length(allFileNames), length(queryVariables));
valueForvariable = cell(length(allFileNames), length(queryVariables));
for i=1:length(allFileNames)
    for j=1:length(queryVariables)
         [valueForvariable{i,j}, hasVariableMask(i,j)] = getValueForQuery(fileKeyValues(allFileNames{i}), queryVariables{j});
    end;
end;

selectedMask = all(hasVariableMask, 2);
foundFiles = allFileNames(selectedMask); % all variables level must be present
foundValues = valueForvariable(selectedMask,:);
end

function [value, valueFound] = getValueForQuery(map, query)
 if any(query == '.')
     parts = strsplit(query, '.');
     [value1, valueFound1] = getValueForQuery(map, parts{1});
     if valueFound1
         
         if iscell(value1) && length(value1) == 1
             value1 = value1{1};
         end;         
         
         if isa(value1, 'containers.Map')              
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