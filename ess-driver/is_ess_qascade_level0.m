function [itIs, recordingFiles, allFilesMapToKeyValues] = is_ess_qascade_level0(folder)
% [itIs, recordingFiles] = is_ess_qascade_level0(folder)
% recordingFiles contains only data recording files (the one for which 'recordingParameters' is
% defined.

[allFilesMapToKeyValues, issues] = qascade_read(folder);
[recordingFiles, values] = qascade_find(allFilesMapToKeyValues, {'recordingParameters', 'recordingParameters.type'});

issues = Issues;

requiredEEGModalityFields = {'samplingRate', 'name', 'startChannel', 'endChannel', ...
    'referenceLocation', 'referenceLabel', 'channelLocationType', 'channelLabels', ...
    'nonScalpChannelLabels'};

textPart = 'type ''EEG'' of recordingParameters';

recognizedReferenceLocationValues  = {'Right Mastoid', 'Left Mastoid', 'Mastoids', 'Linked Mastoids' 'Cz' 'CMS' 'Left Ear' 'Right Ear', 'Ears', 'Average' 'Nasion', 'Nose' 'WCT'};

recordingParametSetsForFiles = values(:,1); % a cell conatining maps, one for each file.
for i=1:length(recordingParametSetsForFiles)
    for j=1:length(recordingParametSetsForFiles{i})
        % go over different modalities (each having .type, .samplingRate, etc).
        modality = map_to_struc(recordingParametSetsForFiles{i}{j}); % finally, a structure
        if strcmpi(modality.type, 'EEG')
          
            [issues, fineFields, missingFields, emptyFields] = check_fields_present_and_non_empty(modality, requiredEEGModalityFields, recordingFiles{i}, issues, textPart);
            
            if all(ismember({'channelLabels' 'startChannel' 'endChannel'}, fineFields))
                if length(modality.channelLabels) ~= (1 + modality.endChannel - modality.startChannel)
                    issues.addError(sprintf('Number of channel labels does not match ''endChannel - startChannel + 1'' in type ''EEG'' of recordingParameters of file ''%s''.\n', recordingFiles{i}));
                end;
            end;
            
            if ismember('referenceLocation', fineFields)
                if ~ismember(modality.referenceLocation, recognizedReferenceLocationValues)
                    issues.addWarning(sprintf(' ''referenceLocation'' value set to ''%s'' and provided in type ''EEG'' of recordingParameters of file ''%s'' does not belong to any of the recognized values (%s) in ESS schema.\n', modality.referenceLocation, recordingFiles{i}, strjoin_adjoiner_first(', ', recognizedReferenceLocationValues)));
                end;
            
            end;
            
            
        end;
    end;
end;

if isempty(recordingFiles)
    itIs = 0;
    
    fprintf('\n\nNo recording files detected.\n');
else
    issues.show;
    itIs = ~any(strcmp(issues.types, 'error'));
end;