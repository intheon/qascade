classdef Issues < handle
    %Issues A Handle class containing errors and warning (could bex extended to suggestions, etc). 
    %   Holds and displayes errors and warnings.
    
    properties
        texts % a cell array containing the text of error or warning
        types
    end
    
    methods
        function addError(obj, errorText)
            
            % prevent adding multiples of the same issue.
            duplicateId = find(strcmp(obj.texts, errorText)); 
            if ~isempty(duplicateId) && strcmp(obj.types{duplicateId}, 'error')
                return;
            end;
            
            obj.texts{end+1} = errorText;
            obj.types{end+1} = 'error';
        end;
        
        function addWarning(obj, warningText)
                                    
            duplicateId = find(strcmp(obj.texts, warningText)); 
            if ~isempty(duplicateId) && strcmp(obj.types{duplicateId}, 'warning')
                return;
            end;
            
            obj.texts{end+1} = warningText;
            obj.types{end+1} = 'warning';
        end;
        
        function itDoes = existsAny(obj)
            itDoes = ~isempty(obj.texts);
        end;
        
        function show(obj)
            errorIds = find(strcmp(obj.types, 'error'));
            warningIds = find(strcmp(obj.types, 'warning'));
            
            if any(errorIds)
                fprintf('\nErrors:\n\n');
                for i=1:length(errorIds)
                    fprintf('%d- %s\n\n', i, strjoin_adjoiner_first(sprintf('\n'), linewrap(obj.texts{errorIds(i)},100)));
                end;
                fprintf('\n');
            end;
            
              if any(warningIds)
                fprintf('\nWarnings:\n\n');
                for i=1:length(warningIds)
                    fprintf('%d-%s\n\n', i, strjoin_adjoiner_first(sprintf('\n'), linewrap(obj.texts{warningIds(i)},100)));
                end;
                fprintf('\n');
            end;
            
        end;
    end
    
end

