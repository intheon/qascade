function [itIs, studyObj, recordingFiles, allFilesMapToKeyValues] = is_ess_qascade_level1(folder)
% [itIs, studyObj, recordingFiles, allFilesMapToKeyValues] = is_ess_qascade_level1(folder)


    function out = assignFieldToField(fromStruct, toStruct, fromFields, toFields)
        % out = assignFieldToField(fromStruct, toStruct, fromFields, toFields)
        % assign 'fromFields' fields of the structure fromStruct, to 'toFields' of the structure
        % toStruct. If a field did not exist in fromStruct, place empty string  '' there.
        % if 'toFields' is omitted, it will be assumed to be equal to fromFields.
        
        if nargin < 4
            toFields = fromFields;
        end;
        
        out = toStruct;
        if isstruct(fromStruct)
            fromFieldNames = fieldnames(fromStruct);
        else
            fromFieldNames = {};
        end;
        
        for ii=1:length(toFields)
            if ismember(fromFields{ii}, fromFieldNames)
                if ischar(fromStruct.(fromFields{ii}))
                    out.(toFields{ii}) = fromStruct.(fromFields{ii});
                elseif isnumeric(fromStruct.(fromFields{ii}))
                    out.(toFields{ii}) = num2str(fromStruct.(fromFields{ii}));
                elseif iscell(isnumeric(fromStruct.(fromFields{ii})))
                    fromStruct.(fromFields{ii}) = fromStruct.(fromFields{ii}){1};
                    out = assignFieldToField(fromStruct, out, fromFields(ii), toFields(ii));
                end;
            else
                out.(toFields{ii}) = '';
            end;
        end
    end

    function out = fieldOrEmpty(s, field)
        % returns eithe the field or an empty value
        if isfield(s, 'field')
            out = s.(field);
        else
            out = '';
        end;
    end

    function s = makeEmptyFieldsChar(s)
        f = fieldnames(s);
        for ii=1:length(f)
            if isempty(s.(f{ii}))
                s.(f{ii}) = '';
            end;
        end;
    end

    function s = makeAllString(s)
        if isnumeric(s)
            s = num2str(s);
            return;
        elseif isstruct(s) || isobject(s)
            
            f = fieldnames(s);
            for ii=1:length(f)
                
                fieldvalue = s.(f{ii});
                
                if isempty(fieldvalue)
                    s.(f{ii}) = '';
                else
                    
                    if ~ischar(fieldvalue)
                        for jj = 1:length(fieldvalue)
                            returned{jj} = makeAllString(fieldvalue(jj));
                        end
                        
                        
                        t = returned{1};
                        for jj=2:length(fieldvalue)
                            t(jj) = returned{jj};
                        end
                        
                        s.(f{ii}) = t;
                    end;
                end;
                
            end;
        end
    end


itIs = false;
studyObj = [];

[itIsLevel0, recordingFiles, allFilesMapToKeyValues] = is_ess_qascade_level0(folder);

if itIsLevel0
    [filesInStudy, values] = qascade_find(allFilesMapToKeyValues, {'study'});
    
    if isempty(filesInStudy)
        fprintf('No ''study'' key is defined.\n');
        return;
    end;
    
    study = unique_universal(values(:,1)); % a cell conatining maps, one for each file.
    
    if length(study) > 1
        fprintf('Expected only one unique ''study'' key but found %d.\n', length(study));
        return;
    end;
    
    study = map_to_struc(study{1});
    issues = Issues;
    [issues, fineFields, missingFields, emptyFields] = check_fields_present_and_non_empty(study, {'description'    'shortDescription'  'title' 'allSubjectsHealthyAndNormal' 'hedVersion' 'organizations'}, [], issues, '''study'' key');
    
    allStudyFilesMapToKeyValues = allFilesMapToKeyValues.copy(filesInStudy);
    allStudyRecordingFilesKeyValues = allStudyFilesMapToKeyValues.copy(recordingFiles);
    
    % need to select recording file that are in the study (there may be recording files outside the
    % study)
    
    requiredDataRecordingFields = {'recordingParameters', 'tasks', 'tasks.taskLabel', 'eventCodes', 'eventCodes.code' 'session.id', 'startDateTime'};
    [studyRecordingFilesWithRequiredDataRecordingFields, values, allFileNames, hasVariableMask] = qascade_find(allStudyRecordingFilesKeyValues, requiredDataRecordingFields);
    
    for i=1:length(allFileNames)
        if ~all(hasVariableMask(i,:),2)
            issues.addError(sprintf('File ''%s'' is missing fields: %s\n', allFileNames{i}, strjoin_adjoiner_first(', ', requiredDataRecordingFields(~hasVariableMask(i,:)))));
        end;
    end;
    
    if issues.numberOfErrors == 0
        studyObj = level1Study;
        studyObj.studyTitle = study.title;
        studyObj.studyShortDescription = study.shortDescription;
        studyObj.studyDescription = study.description;
        
        try
            studyObj.eventSpecificationMethod = study.eventSpecificationMethod;
        catch
            studyObj.eventSpecificationMethod = 'Codes';
        end
        
        if ischar(study.allSubjectsHealthyAndNormal)
            studyObj.summaryInfo.allSubjectsHealthyAndNormal = study.allSubjectsHealthyAndNormal;
        else
            if study.allSubjectsHealthyAndNormal
                studyObj.summaryInfo.allSubjectsHealthyAndNormal = 'Yes';
            else
                studyObj.summaryInfo.allSubjectsHealthyAndNormal = 'No';
            end;
        end;
        
        studyObj.summaryInfo.license = assignFieldToField(study.license, studyObj.summaryInfo.license, {'type' 'text' 'link'});
        
        studyObj.contactInfo = assignFieldToField(study.contact, studyObj.contactInfo, {'phone' 'email'});
        studyObj.contactInfo.name = strtrim([fieldOrEmpty(study.contact, 'givenName') ' '  fieldOrEmpty(study.contact, 'additionalName') ' '  fieldOrEmpty(study.contact, 'familyName')]);
        
        try
            studyObj.projectInfo.organization = study.projectFunding(1).organization;
            studyObj.projectInfo.grantId = study.projectFunding(1).grantId;
            if length(study.projectFunding) > 1
                issues.addWarning('There is more than one ''projectFunding'' present, but only the first one is read since currently ESS XML only supports a single organization.');
            end;
        catch
        end;
        
        studyObj = assignFieldToField(study, studyObj, {'publications' 'copyright' 'IRB' 'hedVersion'}, {'publicationsInfo', 'copyrightInfo', 'irbInfo', 'hedVersion'});
        
        
        for i=1:length(study.experimenters)
            studyObj.experimentersInfo.name = strtrim([fieldOrEmpty(study.experimenters(i), 'givenName') ' '  fieldOrEmpty(study.experimenters(i), 'additionalName') ' '  fieldOrEmpty(study.experimenters(i), 'familyName')]);
            studyObj.experimentersInfo = assignFieldToField(study.experimenters(i), studyObj.experimentersInfo, {'role'});
        end;
        
        [uniqueTaskMaps, ~, taskMapId] = unique_universal(values(:,2));
        taskInfoTemplate = studyObj.tasksInfo(1);
        for i=1:length(uniqueTaskMaps)
            taskmap = uniqueTaskMaps{i};
            if iscell(taskmap)
                taskmap = taskmap{1};
            end;
            
            taskstruct = map_to_struc(taskmap);
            studyObj.tasksInfo(i) = assignFieldToField(taskstruct, taskInfoTemplate, {'description', 'tags', 'taskLabel'}, {'description', 'tag', 'taskLabel'});
        end;
        
        [uniqueEventCodeTaskMaps, ~, eventCodeMapId] = unique_universal(values(:,4));
        eventCodesInfoTemplate = studyObj.eventCodesInfo;
        for i=1:length(uniqueEventCodeTaskMaps)
            eventmap = uniqueEventCodeTaskMaps{i};
            if iscell(eventmap)
                eventmap = eventmap{1};
            end;
            eventstruct = map_to_struc(eventmap);
            
            studyObj.eventCodesInfo(i) = eventCodesInfoTemplate;
            
            studyObj.eventCodesInfo(i).code = eventstruct.code;
            if isfield(eventstruct, 'taskLabel')
                studyObj.eventCodesInfo(i).taskLabel = eventstruct.taskLabel;
            else
                studyObj.eventCodesInfo(i).taskLabel = '';
            end;
            
            studyObj.eventCodesInfo(i).condition = assignFieldToField(eventstruct, studyObj.eventCodesInfo(i).condition, {'label', 'description', 'tags'}, {'label', 'description', 'tag'});
        end;
        
        % recording parameter sets
        fileToRecordingParamsMap = OrderedMap;
        [uniqueRecordingParametersMaps, ~, recordingParametersMapId] = unique_universal(values(:,1));
        modalityTemplate = studyObj.recordingParameterSet(1).modality(1);
        for i=1:length(uniqueRecordingParametersMaps)
            rpMap = uniqueRecordingParametersMaps{i};
            studyObj.recordingParameterSet(i).recordingParameterSetLabel = ['parameter_set_' num2str(i)];
            
            % assign recording parameter labels to data recordings
            ids = find(recordingParametersMapId == i);
            for j=1:length(ids)
                fileToRecordingParamsMap(studyRecordingFilesWithRequiredDataRecordingFields{ids(j)}) = studyObj.recordingParameterSet(i).recordingParameterSetLabel;
            end;
            
            for j=1:length(rpMap)
                modalityStruct = map_to_struc(rpMap{j});
                fields = fieldnames(modalityStruct);
                for k=1:length(fields)
                    if iscell(modalityStruct.(fields{k}))
                        modalityStruct.(fields{k}) = strjoin_adjoiner_first(', ', modalityStruct.(fields{k}));
                    end;
                end;
                % becuase nonScalpChannelLabels and nonScalpChannelLabels must be mapped
                % to nonScalpChannelLabel and nonScalpChannelLabel
                studyObj.recordingParameterSet(i).modality(j) = assignFieldToField (modalityStruct, modalityTemplate,...
                    {'channelLabels'    'channelLocationType'    'description'    'endChannel'    'name'    'nonScalpChannelLabels'     'referenceLabel'  ...
                    'referenceLocation'    'samplingRate'    'startChannel'    'type'}, {'channelLabel'    'channelLocationType'   ...
                    'description'    'endChannel'    'name'    'nonScalpChannelLabel'    'referenceLabel'    'referenceLocation'    'samplingRate' ...
                    'startChannel'    'type'});
                studyObj.recordingParameterSet(i).modality(j) = makeEmptyFieldsChar(studyObj.recordingParameterSet(i).modality(j));
            end;
        end;
        
        % find out how many session-task tuples are there
        sessionId = values(:,6);
        for i=1:length(sessionId)
            if isnumeric(sessionId{i})
                sessionId{i} = num2str(sessionId{i});
            end;
        end;
        
        taskLabels = values(:,3);
        
        
        % map session IDs to ESS XML session numbers
        startDateTimes = values(:,7);
        for i=1:length(startDateTimes)
            if isempty(datenum8601(startDateTimes{i}))
                startDateNums(i) = 0;
                issues.addError(sprintf('''startDateTime'' value ''%s'' for file %s is not in ISO-8601 time format.\n', startDateTimes{i}, studyRecordingFilesWithRequiredDataRecordingFields{i}));
            else
                startDateNums(i) = datenum8601(startDateTimes{i});
            end;
        end;
        
        [uSessionid, ~, ids] = unq(sessionId);
        
        if any(isnan(str2double(sessionId))) % some session IDs are not numbers, assign session numbers based on their earliest recording
            
            fprintf('Session IDs created based on the earliest data recording in each session.\n');
            
            for i=1:length(uSessionid)
                recIds = find(ids == i);
                minSessionStartDateNum(i) = min(startDateNums(recIds));
            end;
            
            [~, minSessionStartDateNum] = sort(startDateNums, 'ascend');
            
            sessionIdToNumberMap = OrderedMap;
            for i=1:length(uSessionid)
                sessionIdToNumberMap(uSessionid{i}) = num2str(minSessionStartDateNum(i));
            end;
            
        else % all session IDs are numbers, so use them directly as session numbers
            fprintf('Session IDs directly mapped from provided numbers.\n');
            for i=1:length(uSessionid)
                sessionIdToNumberMap(uSessionid{i}) = uSessionid{i};
            end;
        end;
        
        
        for i=1:length(studyRecordingFilesWithRequiredDataRecordingFields)
            map  = allStudyRecordingFilesKeyValues(studyRecordingFilesWithRequiredDataRecordingFields{i});
            session = map_to_struc(map('session'));
            
            if isfield(session, 'notes')
                sessionNotes{i} = session.notes;
            else
                sessionNotes{i} = struct('text','','link','','linkLabel','');
            end;
        end;
        
        sessionTaskTuple = struct;
        for i=1:length(sessionId)
            sessionTaskTuple(i).sessionId = sessionId{i};
            sessionTaskTuple(i).taskLabel = taskLabels{i};
        end;
        
        for i=1:length(studyRecordingFilesWithRequiredDataRecordingFields)
            map  = allStudyRecordingFilesKeyValues(studyRecordingFilesWithRequiredDataRecordingFields{i});
            if isKey(map, 'subjects')
                subject{i} = map_to_struc(map('subjects'));
            else
                subject{i} = {};
            end
        end;
        
        subjectTemplateStructure = studyObj.sessionTaskInfo(1).subject(1);
        [uniqueSessionTaskTuples, ids] = uniqe_struct(sessionTaskTuple);
        for i=1:length(uniqueSessionTaskTuples)
            studyObj.sessionTaskInfo(i).sessionNumber = sessionIdToNumberMap(sessionTaskTuple(ids(i)).sessionId);
            studyObj.sessionTaskInfo(i).labId = sessionTaskTuple(ids(i)).sessionId;
            
            studyObj.sessionTaskInfo(i).taskLabel = sessionTaskTuple(ids(i)).taskLabel;
            if iscell(studyObj.sessionTaskInfo(i).taskLabel)
                studyObj.sessionTaskInfo(i).taskLabel = strjoin_adjoiner_first(', ', studyObj.sessionTaskInfo(i).taskLabel);
            end;
            
            studyObj.sessionTaskInfo(i) = assignFieldToField(sessionNotes{i}, studyObj.sessionTaskInfo(i), {'text', 'link' 'linkLabel'}, {'note', 'link', 'linkName'});
            
            studyObj.sessionTaskInfo(i).subject = subjectTemplateStructure;
            if isempty(subject{i})
                studyObj.sessionTaskInfo(i).subject.medication = makeEmptyFieldsChar(studyObj.sessionTaskInfo(i).subject.medication);
                studyObj.sessionTaskInfo(i).subject = makeEmptyFieldsChar(studyObj.sessionTaskInfo(i).subject);
            else
                
                studyObj.sessionTaskInfo(i).subject = assignFieldToField(subject{i}, studyObj.sessionTaskInfo(i).subject, {'id', 'YOB', 'age', 'gender', 'group', 'hand' 'vision' 'hearing' 'height' 'weight' 'channelLocations'}, {'labId', 'YOB', 'age', 'gender', 'group', 'hand' 'vision' 'hearing' 'height' 'weight' 'channelLocations'});
                
                % in ESS XML we use single-letter gender identifiers, in ESS Qascade we use full
                % gender names.
                switch lower(studyObj.sessionTaskInfo(i).subject.gender)
                    case 'male'
                        studyObj.sessionTaskInfo(i).subject.gender = 'M';
                    case 'female'
                        studyObj.sessionTaskInfo(i).subject.gender = 'F';
                    case 'other'
                        studyObj.sessionTaskInfo(i).subject.gender = 'O';
                    case 'na'
                        studyObj.sessionTaskInfo(i).subject.gender = 'NA';                    
                end;
                
                % in ESS XML we use single-letter handedness identifiers, in ESS Qascade we use full
                % names.
                switch lower(studyObj.sessionTaskInfo(i).subject.hand)
                    case 'right'
                        studyObj.sessionTaskInfo(i).subject.hand = 'R';
                    case 'left'
                        studyObj.sessionTaskInfo(i).subject.hand = 'L';
                    case 'Ambidextrous'
                        studyObj.sessionTaskInfo(i).subject.hand = 'A';
                    case 'na'
                        studyObj.sessionTaskInfo(i).subject.hand = 'NA';
                end;
                                        
                % subject medication
                studyObj.sessionTaskInfo(i).subject.medication = assignFieldToField(subject{i}, studyObj.sessionTaskInfo(i).subject.medication, {'caffeine', 'alcohol'});
            end;
            
            
            % data recording files
            filenameIds = find(ids == i); % find potentially multiple files for the (session, task) tuple.
            for j=1:length(filenameIds)
                studyObj.sessionTaskInfo(i).dataRecording.filename = [folder filesep studyRecordingFilesWithRequiredDataRecordingFields{filenameIds(j)}];
                studyObj.sessionTaskInfo(i).dataRecording.startDateTime = startDateTimes{filenameIds(j)};
                studyObj.sessionTaskInfo(i).dataRecording.recordingParameterSetLabel = fileToRecordingParamsMap(studyRecordingFilesWithRequiredDataRecordingFields{filenameIds(j)});
                studyObj.sessionTaskInfo(i).dataRecording.dataRecordingUuid = '';
                studyObj.sessionTaskInfo(i).dataRecording.eventInstanceFile = '';
            end;
        end;
    end;
    
    studyObj = makeAllString(studyObj);        
    
    if issues.numberOfErrors == 0
        
        fprintf('Qascade: \n');
        issues.show;
        
        fprintf('ESS Tools validation: \n');
        [studyObj, validationIssues, numberOfMissingFileIssues, numberOfXMLIssues] = studyObj.validate;
        
        itIs = numberOfMissingFileIssues == 0 &&  numberOfXMLIssues == 0;
        
        if itIs
            fprintf('\n The Qascade container adheres to ESS Level 1 Qascade schema.\n');
        else
            fprintf('\nThe Qascade container does NOT adhere to ESS Level 1 Qascade schema due to the outstanding issues above.\n');
        end;
    else
        fprintf('The Qascade container does NOT ahere to with ESS Level 1 Qascade schema due to the following issues:\n');
        issues.show;
    end;
else
    fprintf('The provided Qascade container is not an ESS Level 0 container and hence not an ESS Level 0 container.\n')
end;
end