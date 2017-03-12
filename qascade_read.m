function [filesMapToKeyValues, issues] = qascade_read(folder, parentKeyValues, fileDirective, rootFolder, issues)
% [filesMapToKeyValues, issues] = qascade_read(folder);
% adheres to Qascade schema version 1.0.0
% returns one key per file, with paths relative to the root container folder ('folder' input argument). 
% file separators are in the format on which the function is running, i.e. \ for Windows and / for Linux.



filesMapToKeyValues = containers.Map; % file keys are the (file: (key:value)) pairs.

if ~exist(folder, 'dir')
    error('Input folder does not exist');
end;

if ~exist('issues', 'var')
    issues = Issues;
end;

if exist('parentKeyValues', 'var')
    folderKeys = parentKeyValues; % folder keys are the (key:value) pairs that are common to all files in the folder.
else
    folderKeys = newEmptyMap;
end;

%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% this needs to be changed to a struct with fields:
% .directiverType
% .directivepayload
% this is to avoid overwriting parent directives, which currently happen due to the use of maps.
if ~exist('fileDirective', 'var')
    fileDirective.match = newEmptyMap;
    fileDirective.extract = newEmptyMap;
end;

% make sure that folder variable does not have a file separator (since we do not want double file
% separators anywhere)
if folder(end) == filesep
    folder = folder(1:(end-1));
end;

if ~exist('rootFolder', 'var') % root folder should not have a file separator at the end
    if folder(end) == filesep
        rootFolder = folder(1:end-1);
    else
        rootFolder = folder;
    end;
end;

manifestFileName = 'manifest.qsc.yaml';


% get the list of files and folders
d = dir(folder);
d(1:2) = [];
names = {d.name};
subfolderMask = [d.isdir];

subfolders = names(subfolderMask);
files = names(~subfolderMask);


% look for the manifest file in the folder, exclude it from the list of files, and process it.
id = strcmp(files, manifestFileName);
if any(id)
    files(id) = []; % remove the manifest from the list of payload files.
    newFolderKeyValues = ReadYamlRawMap([folder filesep manifestFileName]);
else
    newFolderKeyValues = newEmptyMap;
end;

[filesMapToKeyValues, folderKeys, fileDirective, onlyThisFolderKeys] = process_manifest_keys(folder, rootFolder, files, newFolderKeyValues, filesMapToKeyValues,...
    folderKeys, fileDirective, manifestFileName, issues);

% add file keys for the subfolder
for i=1:length(subfolders)
    % copyMap is because container.Map is a handle class, hence
    % sending it inside a function can change its value
    
    newFileKeys = qascade_read([folder filesep subfolders{i}], copyMap(folderKeys), fileDirective, rootFolder, issues);
    filesMapToKeyValues = [filesMapToKeyValues; newFileKeys];
end;

if nargin == 1 && issues.existsAny
    issues.show;
end
end
%%


function [filesMapToKeyValues, folderKeyValues, fileDirective, onlyThisFolderKeys] = process_manifest_keys(folder, rootFolder, files, ...
    newFolderKeyValues, filesMapToKeyValues, folderKeyValues, fileDirective, manifestFileName, issues)

matchDirective = 'matches';
tableDirective = 'table';
noSubfolderDirective = 'no-subdir';
extractDirective = 'extract';
versionDirective = 'qascade version';

onlyThisFolderKeys = newEmptyMap;

% overwrite keys by the ones present in the manifest file
keys = newFolderKeyValues.keys;

for i = 1:length(keys)
    if ~isempty(regexp(keys{i}, ['^(' matchDirective '.*\)$'], 'once')) %  ^ in the beginning indices that it has to start with (, $ indicates that it has to end with )
        matchPattern = keys{i}((length(matchDirective)+3):(end-1));
        if isKey(fileDirective.match, matchPattern)
            fileDirective.match(matchPattern) = [fileDirective.match(matchPattern); newFolderKeyValues(keys{i})];
        else
            fileDirective.match(matchPattern) = newFolderKeyValues(keys{i});
        end;
    elseif ~isempty(regexp(keys{i}, ['^(' tableDirective '.*\)$'], 'once')) %  ^ in the beginning indices that it has to start with (, $ indicates that it has to end with )
        % table name is not important
        
        % first try and see if the provided string resolves to an existing
        % file name in the container.
        tableFileName = strrep([folder filesep newFolderKeyValues(keys{i})], '/', filesep);
        
        if exist(tableFileName, 'file')
            % need to copy the file into a file with txt extension for
            % readtable() to be able to read it.
            newFileName = [tempname '.txt'];
            copyfile(tableFileName, newFileName);
            tableFileName = newFileName;
        else
            % write to a temporary file and use readtable to import as tsv file
            tableFileName = [tempname '.txt'];
            fid = fopen(tableFileName, 'w');
            fprintf(fid, newFolderKeyValues(keys{i}));
            fclose(fid);
        end;
        
        try
            warning('off', 'MATLAB:table:ModifiedVarnames');
            tble = readtable(tableFileName,'Delimiter','\t','ReadVariableNames',true);
            tbleNoVariableNames = readtable(tableFileName,'Delimiter','\t','ReadVariableNames',false); % used to  read unmodified variable names
            warning('on', 'MATLAB:table:ModifiedVarnames');
            delete(tableFileName);
            keyNames = tbleNoVariableNames{1,:};
            if strcmp(keyNames{1}, '(matches)')
                for j=1:height(tble)
                    map = newEmptyMap;
                    
                    for k=2:width(tble) % extract key:value pairs from the tabel, into a map,then assign that map to the match pattern in fileDirective.match.
                        value = tble{j,k};
                        if ischar(value)
                            switch value % because outside of the table, YAML reader converts 'true' to 1 and 'false' to 0
                                case 'true'
                                    value = 1;
                                case 'false'
                                    value = 0;
                            end;
                        end;
                        map(keyNames{k}) = value;
                    end;
                    matchPattern = cell2mat(tble{j, 'x_matches_'});
                    if isKey(fileDirective.match, matchPattern)
                        fileDirective.match(matchPattern) = [fileDirective.match(matchPattern); map];
                    else
                        fileDirective.match(matchPattern) = map;
                    end;
                    
                end;
            else
                issues.addError(sprintf('Error: The the table specified in key ''%s'' of file %s does not have ''(matches)'' as its first column header.', keys{i}, [folder filesep manifestFileName]));
            end
        catch e
            issues.addError(sprintf('The the table specified in key ''%s'' of file %s is malformed (is not tab-separated and/or have a different number of columns at different rows).', keys{i}, [folder filesep manifestFileName]));
        end;
    elseif ~isempty(regexp(keys{i}, ['^(' noSubfolderDirective '.*\)$'], 'once')) %  ^ in the beginning indices that it has to start with (, $ indicates that it has to end with )
        onlyThisFolderKeys = newFolderKeyValues(keys{i});
    elseif ~isempty(regexp(keys{i}, ['^(' extractDirective '.*\)$'], 'once')) %  ^ in the beginning indices that it has to start with \([, $ indicates that it has to end with )
        extractPattern = keys{i}((length(extractDirective)+3):(end-1));
        
        if ~isempty(strfind(extractPattern, ']['))
            issues.addError(sprintf('In file ''%s'': the extraction pattern in directive ''(extract %s)'' is invalid because it contains two keys next to each other, i.e. [key1][key2].', [folder filesep manifestFileName], keys{i}));
        end;
        
        if ~isempty(strfind(extractPattern, '*[')) || ~isempty(strfind(extractPattern, ']*'))
            issues.addError(sprintf('In file ''%s'': the extraction pattern in directive ''(extract %s)'' is invalid because it contains a wildcard next to a key, i.e. *[key1] or [key2]*.', [folder filesep manifestFileName], keys{i}));
        end;
        
        if ~isempty(strfind(extractPattern, '**'))
            issues.addWarning(sprintf('In file ''%s'': the extraction pattern in directive ''(extract %s)'' is invalid because it contains two wildcard next to each other, i.e. **. Converted to a single wildcard.', [folder filesep manifestFileName], keys{i}));
            extractPattern = strrep(extractPattern, '**', '*');
        end;
        
        if isempty(extractPattern)
            issues.addError(sprintf('In file ''%s'': the extraction pattern in directive (extract) is empty.', [folder filesep manifestFileName]));
        elseif extractPattern(end) == '/' % any pattern that has / at the end is interpretaed as a folder, matching all the files inside the folder (including subfolders)
            extractPattern = [extractPattern '*'];
        end;
        
        if (strcmpi(newFolderKeyValues(keys{i}), 'direct') || isa(newFolderKeyValues(keys{i}), 'containers.Map'))
            if isKey(fileDirective.extract, extractPattern) % add it to already existing directives
                fileDirective.extract(extractPattern) = [fileDirective.extract(matchPattern); newFolderKeyValues(keys{i})];
            else
                fileDirective.extract(extractPattern) = newFolderKeyValues(keys{i});
            end;
        else
            issues.addError(sprintf('In file ''%s'': the value assigned to directive ''(extract %s)'' is invalid. It should either be the string ''direct'' or a dictionary mapping extracted strings to their intended values.', [folder filesep manifestFileName], keys{i}));
        end;
    elseif ~isempty(regexp(keys{i}, ['^(' versionDirective '.*\)$'], 'once'))
        version = newFolderKeyValues(keys{i});
        fprintf('Manifest ''%s'' adheres to Qascade schema version %s.\n', [folder filesep manifestFileName], version);
    else
        folderKeyValues = addExtendedKeyToMap(folderKeyValues, keys{i}, newFolderKeyValues(keys{i}), [folder filesep manifestFileName], issues);
    end;
end

if ~isempty(onlyThisFolderKeys)
    fileDirectiveCopy.match = copyMap(fileDirective.match);
    fileDirectiveCopy.extract = copyMap(fileDirective.extract);
    [onlyThisFolderFilekeys, onlyThisFolderFolderKeys, folderOnlyfileDirective.match, onlyThisFolderKeys] = process_manifest_keys(folder, rootFolder, files, onlyThisFolderKeys, copyMap(filesMapToKeyValues)...
        , copyMap(folderKeyValues), fileDirectiveCopy, manifestFileName, issues);
end;

% add file keys for the current folder
for i=1:length(files)
    filesMapToKeyValues(filepathKey(folder, files{i}, rootFolder)) = folderKeyValues;
end;

% apply file match directives (overwrite keys for files matching certain wildcard expressions)
keys = fileDirective.match.keys;
for i=1:length(keys)
    
    % create full paths but exclude the root folder so it is not used in pattern matching (this
    % makes the container portable)
    % fullPaths = strcat([folder((length(rootFolder)+1):end) filesep], files);
    % matchIds = find(~cellfun(@isempty, regexp(fullPaths, regexptranslate('wildcard', keys{i})))); % match the full file path, including the name.
    
    % unclear whether relative folder matching works
    fullPaths = strcat([folder filesep], files);
    if keys{i}(end) ==  '/' % if it end with / then it is anywhere (under the root of the container)
        [list, isDir] = glob([rootFolder filesep '**' keys{i}]);
    else % if it starts with / then it is relative to the manifest folder
        [list, isDir] = glob([folder filesep keys{i}]);
    end;
    matchIds = ismember(fullPaths, list(~isDir));
    
    if any(strcmp(folder, list(isDir))) || any(strcmp([folder filesep], list(isDir)))
        matchIds(:) = true;
    end;
    matchIds = find(matchIds);
    % assert(isequal(matchIds_old, matchIds));
    
    % overwrite keys when a file name matched wildcard
    for j=1:length(matchIds)
        filename = filepathKey(folder,files{matchIds(j)}, rootFolder);
        
        % extended map includes field overwrites (a.b.c)
        filesMapToKeyValues(filename) = addExtendedMapToMap(filesMapToKeyValues(filename), fileDirective.match(keys{i}),...
            [folder filesep manifestFileName], issues);
    end;
    
end;



% apply extraction of values for keys matching xyz[key]abc.123 patters
keys = fileDirective.extract.keys;

for typeOfFiles = 1:2
    % apply the extraction twice, once of just file names (no paths) and
    % the other on full filenames, including relative paths to the root of
    % the container.
    
    switch typeOfFiles
        case 1
            fileToExtractFrom = files;
        case 2
            for i=1:length(files)
                fileToExtractFrom{i} = strrep([folder((length(rootFolder)+2):end) filesep  files{i}], '\', '/'); % we always use unix path format / for matching.
            end;
    end;
    
    
    for i=1:length(keys)
        
        if typeOfFiles == 1 || (typeOfFiles == 2 && ~isempty(strfind(keys{i}, '/'))) % only search full paths for keys that contain /
            
            key_values_cell = extract_key_values_from_filenames(fileToExtractFrom, keys{i});
            
            % overwrite keys with extracted values
            for j=1:length(key_values_cell)
                if ~isempty(key_values_cell{j})
                    filename = filepathKey(folder, files{j}, rootFolder);
                    
                    if strcmpi(fileDirective.extract(keys{i}), 'direct')
                        % extended map includes field overwrites (a.b.c)
                        filesMapToKeyValues(filename) = addExtendedMapToMap(filesMapToKeyValues(filename),  key_values_cell{j},...
                            [folder filesep manifestFileName], issues);
                    elseif isa(fileDirective.extract(keys{i}), 'containers.Map') % when an alternative mapping between extracted values and the values to be set is presented under (extract ..) directive.
                        extractedKeys = key_values_cell{j}.keys;
                        for k = 1:length(extractedKeys)
                            if fileDirective.extract(keys{i}).isKey(extractedKeys{k}) % there is match between an item under the 'extract directive and one of the keys
                                map = fileDirective.extract(keys{i});
                                mapsForExtractedKey = map(extractedKeys{k}); % this contains how to map different values to other values, e.g. 'eo' to 'eyes-open'
                                
                                %                         (extract sometitle_S[subjectNumber]_T[taskLabel].set):
                                %                            taskLabel:
                                %                              r: resting % we are here, if there is a match
                                %                              ec: eyes-closed
                                %                              eo: eyes-open
                                
                                if mapsForExtractedKey.isKey(key_values_cell{j}(extractedKeys{k})) % if there was a
                                    valueForExtractedKey = mapsForExtractedKey(key_values_cell{j}(extractedKeys{k}));
                                else
                                    valueForExtractedKey = key_values_cell{j}(extractedKeys{k});
                                end;
                                
                                newMap = containers.Map;
                                newMap(extractedKeys{k}) = valueForExtractedKey;
                            else
                                newMap = containers.Map;
                                newMap(extractedKeys{k}) = key_values_cell{j}(extractedKeys{k});
                            end;
                            
                            filesMapToKeyValues(filename) = addExtendedMapToMap(filesMapToKeyValues(filename),  newMap,...
                                [folder filesep manifestFileName], issues);
                        end;
                    end;
                end;
            end;
        end;
    end;
end;



% add folder-only filesMapToKeyValues last so they take precedence over matches and other keys
if exist('onlyThisFolderFilekeys', 'var')
    keys = onlyThisFolderFilekeys.keys;
    for i=1:length(keys)
        filesMapToKeyValues(keys{i}) = [filesMapToKeyValues(keys{i}); onlyThisFolderFilekeys(keys{i})];
    end;
end;

end


function map = addExtendedMapToMap(map, newMap, manifestFile, issues)
keys = newMap.keys;
map = copyMap(map);
for i =1:length(keys)
    map = addExtendedKeyToMap(map, keys{i}, newMap(keys{i}), manifestFile, issues);
end;
end

%%
function map = addExtendedKeyToMap(map, key, value, manifestFile, issues)
% adds a (key:value) pair to the map, while interpreting key.field.field.. diectives.

if any(key == '.') % the key contains one or more dots, indicating that it could be a subfield overwrite directive
    parts = strsplit(key, '.');
    newMap = nestedKeyOverwrite(map, parts, value, parts(1), manifestFile, issues);
    map = [map; newMap];
else
    map(key) = value;
end;
end

%%
function newMap = nestedKeyOverwrite(map, parts, value, partsTravelled, manifestFile, issues)
% newMap = nestedKeyOverwrite(map, parts)
% overwrites keys specied in 'parts' in the (nested) map.
% If keys are not present at a level, a map is created at that level (equates to creating a MATLAB
% structurewith only the specified field and subfields);

lastKey = length(parts) == 1;

if ~exist('partsTravelled', 'var')
    partsTravelled = {};
end

keyExists = isKey(map, parts{1});

newMap = copyMap(map);

if lastKey && keyExists
    newMap(parts{1}) = value;
elseif lastKey && ~keyExists
    newMap(parts{1}) = value;
elseif ~lastKey && keyExists
    partsTravelled{end+1} = parts{2};
    nextLevel = map(parts{1});
    if isa(nextLevel, 'containers.Map')
        newMap(parts{1}) = nestedKeyOverwrite(nextLevel, parts(2:end), value, partsTravelled, manifestFile, issues);
    else
        issues.addWarning(sprintf('In file %s: ''%s'' overwrite cannot be applied because ''%s'' (the parent key) is not a structure (multi-field entity).', manifestFile,...
            strjoin_adjoiner_first('.', partsTravelled), strjoin_adjoiner_first('.', partsTravelled(1:end-1))));
    end;
elseif ~lastKey && ~keyExists
    partsTravelled{end+1} = parts{2};
    newMap(parts{1})= nestedKeyOverwrite(newEmptyMap, parts(2:end), value, partsTravelled, manifestFile, issues);
end;

end

%%

function newMap = copyMap(map)
% makes a new 'copy by value' copy of the map so e.g. changes inside a function does not affect the
% map variable outside

if isempty(map)
    newMap = newEmptyMap;
else
    newMap = containers.Map(map.keys, map.values, 'UniformValues', false);
end;
end

function map = newEmptyMap
map = containers.Map('UniformValues', false);
end

function out = filepathKey(folder, filename, rootFolder)
% out = filepathKey(folder, filename, rootFolder)

%out = [folder filesep filename];
out = [folder(length(rootFolder)+1:end) filesep filename];
if out(1) == filesep
    out = out(2:end);
end;
end