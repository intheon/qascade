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
% otherwise: if exportPath is not a file with any of the extensions above, 
% the function will create a folder with this name and copy Qascade Container viewer
% file into that folder. You can explore the container content by opening index.html file
% inside this folder in a browser (Chrome recommended).

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
    case {'json' 'jsonp' 'treeview'}
        opt.ForceRootName = false;
        opt.SingletCell = true;  % even single cells are saved as JSON arrays.
        opt.SingletArray = false; % single numerical arrays are NOT saved as JSON arrays.
        json_str = savejson_with_map('', filekvsFullNames, opt);
        
        if strcmp(exportType, 'treeview')
            ownPath = fileparts(mfilename('fullpath'));
            mkdir(exportPath);
            copyfile([ownPath filesep 'qs-viewer-build' filesep '*'], exportPath);
            
            % find the main.xxxx.js file and replace placeholder JSON with qascade JSON
            mainDir = [exportPath filesep 'static' filesep 'js'];
            d = dir(mainDir);
            placeholderString = '{placeholder:0}';
            for di = 1:length(d)
                [~, n, ext] = fileparts(d(di).name);
               if strcmp(ext, '.js') && ~isempty(strfind(n, 'main.'))
                   mainFileName = [mainDir filesep d(di).name];
                   tx = fileread(mainFileName);
                   tx = strrep(tx, placeholderString, json_str);
                   
                   fid= fopen(mainFileName, 'w');
                   fprintf(fid, '%s', tx);
                   fclose(fid);
                   
               end;
            end;
           
            
            
            return
        end;
        
        if strcmp(exportType, 'jsonp')
            json_str = [callbackName '(' json_str ');'];
        end;
        
        fid= fopen(exportPath, 'w');
        fprintf(fid, '%s', json_str);
        fclose(fid);
end;



