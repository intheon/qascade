function fileKeys = read_cascading_file_keys(folder, parentKeys, fileMatcheDirectives, folderMatcheDirectives)
fileKeys = containers.Map;

if exist('parentKeys', 'var')
    folderKeys = parentKeys;
else
    folderKeys = containers.Map;
end;

if ~exist('fileMatcheDirectives', 'var')
    fileMatcheDirectives = containers.Map;
end;

if ~exist('folderMatcheDirectives', 'var')
    folderMatcheDirectives = containers.Map;
end;




manifestFileName = 'manifest.cfk.yaml';
matchPatternFieldName = 'cfk-match-filename';
matchPatternFileNameSubFieldName = 'cfk-filename';
matchPatternFolderNameSubFieldName = 'cfk-foldername';
matchPatternTableSubFieldName = 'cfk-table';

listOfSubFieldNames = {matchPatternFileNameSubFieldName, matchPatternFolderNameSubFieldName, matchPatternTableSubFieldName};

% get the list of files and folders
d = dir(folder);
d(1:2) = [];
names = {d.name};
subfolderMask = [d.isdir];

subfolders = names(subfolderMask);
files = names(~subfolderMask);


% look for the manifest file in the folderm exlude it from the list of files, and process it.
id = strcmp(files, manifestFileName);
if any(id)
    files(id) = []; % remove the manifest from the list of payload files.
    newFolderKeys = ReadYamlRawMap([folder filesep manifestFileName]);
    
    % overwrite keys
    keys = newFolderKeys.keys;
    
    for i = 1:length(keys)
        if isequal(strfind(keys{i}, matchPatternFieldName), 1)
            
            % match individual files
            if isKey(newFolderKeys(keys{i}), matchPatternFileNameSubFieldName)
                matchMap  = newFolderKeys(keys{i});
                matchKeys = matchMap(matchPatternFileNameSubFieldName);
                
                % remove all directives
                for j=1:length(listOfSubFieldNames)
                    matchMap = matchMap.remmove(listOfSubFieldNames{j});
                end;
                
                fileMatcheDirectives(matchKeys) = matchMap;
            end;
            
            % match based on the containing folder
            if isKey(newFolderKeys(keys{i}), matchPatternFolderNameSubFieldName)
                matchMap  = newFolderKeys(keys{i});
                matchKeys = matchMap(matchPatternFileNameSubFieldName);
                
                % remove all directives
                for j=1:length(listOfSubFieldNames)
                    matchMap = matchMap.remmove(listOfSubFieldNames{j});
                end;
                
                folderMatcheDirectives(matchKeys) = matchMap;
            end;
            
            % process inline TSV table 
            
        else
            folderKeys(keys{i}) = newFolderKeys(keys{i});
        end;
    end
end;

% add file keys for the current folder
for i=1:length(files)
    fileKeys([folder filesep files{i}]) = folderKeys;
end;

% apply file match directives (overwrite keys for files matching certain wildcard expressions)
keys = fileMatcheDirectives.keys;
for i=1:length(keys)
    matchIds = find(~cellfun(@isempty, regexp(files,regexptranslate('wildcard', keys{i}))));
    
    % overwrite keys when a file name matched wildcard
    for j=1:length(matchIds)
        fileKeys([folder filesep files{matchIds(j)}]) = [fileKeys([folder filesep files{j}]); fileMatcheDirectives(keys{i})];
    end;
    
end;

% add file keys for the subfolder
for i=1:length(subfolders)
    % this is because container.Map is a handle class, hence 
    % sending it inside a function can change its value
    dummyContainer = containers.Map(folderKeys.keys, folderKeys.values);
    
    newFileKeys = read_cascading_file_keys([folder filesep subfolders{i}], dummyContainer, fileMatcheDirectives, folderMatcheDirectives);
    fileKeys = [fileKeys; newFileKeys];
end;
end