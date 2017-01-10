filekeys = read_cascading_file_keys('/home/nima/data/sample_for_dev/cfk_ess_rsvp');
keyValues = get_key_across_filekeys('studyTitle', filekeys);

if length(unq(keyValues)) > 1
    error('There are multiple study titles in the folder, there has to be only one');
end;

commonKeys = get_common_keys_across_filekeys(filekeys);

unqiueValueCommonKeys = {};
unqiueValueCommonKeysValues = {};
for i=1:length(commonKeys)
    keyValues = get_key_across_filekeys(commonKeys{i}, filekeys);
    if cell_is_all_the_same(keyValues) == 1;
        
        keyValue = keyValues{1};
        
%         if strcmp(commonKeys{i}, 'tasks')
%             keyboard;
%         end;
        
        if isa(keyValue, 'containers.Map')
            keyValue = map_to_struc(keyValue);
        end;
        
        keyValue = map_array_to_struct_array(keyValue);
        
        unqiueValueCommonKeys{end+1} = commonKeys{i};
        unqiueValueCommonKeysValues{end+1} = keyValue;
    end;
end;

unqiueValueCommonKeysMap = containers.Map(unqiueValueCommonKeys, unqiueValueCommonKeysValues);

%% put data in top levels

newObj = level1Study;
s = struct(newObj);
f = fieldnames(s);
for i=1:length(f)
    id = strcmp(f{i}, unqiueValueCommonKeys);
    id = id | strcmp(strrep(f{i}, 'Info', ''), unqiueValueCommonKeys);
    
    % e.g. studyDescription to description
    t = strrep(f{i}, 'study', '');
    t = [lower(t(1)) t(2:end)];
    id = id | strcmp(t, unqiueValueCommonKeys);
    
    if any(id)
        newObj.(f{i}) = unqiueValueCommonKeysValues{id};
    end;
end

newObj.studyUuid = unqiueValueCommonKeysMap('id');

% still need to convert numerical values to strings in arrays
%% extract sessions and data recordings

filenames = filekeys.keys;
fileKeysAsStructs = filekeys.values;
for i=1:length(filenames)
    if isa(fileKeysAsStructs{i}, 'containers.Map')
        fileKeysAsStructs{i} = map_to_struc(fileKeysAsStructs{i});
    end;
    
    fileKeysAsStructs{i} = map_array_to_struct_array(fileKeysAsStructs{i});
end;

sessionsValues = get_key_across_filekeys('session', filekeys);
fileSessionNumbers = get_key_across_map_cellarray('number', sessionsValues);
withSessionNumberMask = ~cellfun(@isempty, fileSessionNumbers);
sessionsValues = fileKeysAsStructs(withSessionNumberMask);
sessionsFiles = filenames(withSessionNumberMask);
[sessionNumbers, ~, ids] = unq(fileSessionNumbers(withSessionNumberMask));

for i=1:length(sessionNumbers)
    
    sessionFiles = sessionsFiles(ids==i);
    sessionsValues = sessionsValues(ids==i);
    record = sessionsValues{1};
    
    sessionNumber = str2double(sessionNumbers(i));
    

    newObj.sessionTaskInfo(sessionNumber).labIds = record.session.labId;
    newObj.sessionTaskInfo(sessionNumber).notes = record.session.notes;
    newObj.sessionTaskInfo(sessionNumber).subject = record.subject;
    newObj.sessionTaskInfo(sessionNumber).sessionNumber = record.session.number;
    
    sessionFileIsRecordingCellValues = get_key_across_cellarray('recordingParameters', sessionsValues);
    sessionFileIsRecording = ~cellfun(@isempty, sessionFileIsRecordingCellValues);
    
    sessionFileIsRecording = find(sessionFileIsRecording);
    for j=1:length(sessionFileIsRecording)
        newObj.sessionTaskInfo(sessionNumber).dataRecording(j).filename = sessionFiles{sessionFileIsRecording(j)};
        newObj.sessionTaskInfo(sessionNumber).dataRecording(j).recordingParameterSetLabel = sessionsValues{sessionFileIsRecording(j)}.recordingParameterSetLabel;
        newObj.sessionTaskInfo(sessionNumber).dataRecording(j).startDateTime = sessionsValues{sessionFileIsRecording(j)}.startDateTime;
    end;
    
    
end;