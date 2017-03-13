classdef OrderedMap < containers.Map & handle
    properties
        keysIsOrder = {}
    end;
    
    methods
        function obj = OrderedMap(varargin)
            obj = obj@containers.Map(varargin{:});
            if length(varargin) > 0 && iscell(varargin{1})
                obj.keysIsOrder = varargin{1}; % keys added as a keySet (cell of strings).
            end;
        end;

        
        function varargout = subsasgn(obj,s, B)
            switch s(1).type
                case '.'                   
                case '()'
                    varargout{1} = subsasgn@containers.Map(obj,s, B);
                    if iscell(s.subs) && length(s.subs) == 1
                        if ~any(strcmp(obj.keysIsOrder, s.subs{1}))
                            obj.keysIsOrder{end+1} = s.subs{1};
                        end;
                    end;
                case '{}'                   
            end
        end
        
        function obj = remove(mapObj,keySet)
            obj = remove@containers.Map(mapObj, keySet);
            
            % remove keys from keysIsOrder property too.
            idMask = false(length(obj.keysIsOrder), 1);
            for i=1:length(obj.keysIsOrder)
                for j=1:length(keySet)
                    if isequal(obj.keysIsOrder{i}, keySet{j})
                        idMask(i) = true;
                        break;
                    end;
                end;
            end;
            
            obj.keysIsOrder(idMask) = [];
        end;
        
        function obj = vertcat(obj, obj2)
            objKeysIsOrder = obj.keysIsOrder;
            obj2KeysIsOrder = obj2.keysIsOrder;
            
            keysOverwritten = intersect(objKeysIsOrder, obj2KeysIsOrder);
            
            obj =  vertcat@containers.Map(obj, obj2);
            obj.keysIsOrder = [setdiff(objKeysIsOrder, keysOverwritten, 'stable') obj2KeysIsOrder];
            % the end result is that keys that are overwritten in obj2, disappear from the order
            % associated with obj and appear with the order as obj2
        end;
    end;
end