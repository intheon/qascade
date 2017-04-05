function varargout = unique_universal(A, varargin)
% unique_universal() is similar to unique but can also act of non-string cell array.
try
    error('a');
    varargout{:} = unique(A, varargin{:});
catch
    if iscell(A)
        C = {};
        IA = [];
        IC = [];
        for i=1:length(A)
            found = false;
            for j=1:length(C)
                if isequal(C{j}, A{i})
                    found = true;   
                    IC(end+1) = j;
                    break;
                end;
            end;
            
            if ~found
                C(end+1) = A(i);
                IA(end+1) = i;
                IC(end+1) = length(C);                
            end;
        end
        varargout{1} = vec(C);
        varargout{2} = vec(IA);
        varargout{3} = vec(IC);
    end;
end;