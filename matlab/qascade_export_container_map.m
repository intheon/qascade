function qascade_export_container_map(folderOrFileKeyValues, exportPath, callbackName)
% function qascade_export_container_map(folderOrFileKeyValues, exportPath, callbackName)
% exports Qascade file metadata for the container specified in folderOrFileKeyValues as
% a file specified in exportPath. The type of exported data is determined by the file extension.
% Supported export file extensions are:
%
% .yaml: export as YAML
% .json: export as JSON
% .js  : export as a JSONP with the callback specified in callbackName.
%        if not callback name is specified 'getData' is used.

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

if ~exist('callbackName', 'var')
    callbackName = 'getData';
end;

filekvsFullNames = nestd_cell_string_to_cell_string(folderOrFileKeyValues);

switch exportType
    case 'yaml'
        WriteYaml(exportPath, filekvsFullNames);
    case {'json' 'jsonp'}
        opt.ForceRootName = false;
        opt.SingletCell = true;  % even single cells are saved as JSON arrays.
        opt.SingletArray = false; % single numerical arrays are NOT saved as JSON arrays.
        json_str = savejson_with_map('', filekvsFullNames, opt);
        
        if strcmp(exportType, 'jsonp')
            json_str = [callbackName '(' json_str ');'];
        end;
        
        fid= fopen(exportPath, 'w');
        fprintf(fid, '%s', json_str);
        fclose(fid);
end;



