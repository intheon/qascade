function qascade_export_container_map(folderOrFileKeyValues, exportPath, JSONPVar)
% function qascade_export_container_map(folderOrFileKeyValues, exportPath)
% 

if ischar(folderOrFileKeyValues)
    folderOrFileKeyValues = qascade_read(folderOrFileKeyValues);
end;

[p, name, ext] = fileparts(exportPath);

switch ext
    case '.yaml'
        exportType = 'yaml';
    case '.js'
        exportType = 'jsonp';
    case '.json'
        exportType = 'json';
    otherwise
        exportType = 'treeview';
end;

if ~exist('JSONPVar', 'var')
    JSONPVar = 'data';
end;

filekvsFullNames = nestd_cell_string_to_cell_string(folderOrFileKeyValues);
WriteYaml(exportPath, filekvsFullNames);