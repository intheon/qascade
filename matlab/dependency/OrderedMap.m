classdef OrderedMap < containers.Map & handle
    properties
        keysInOrder = {}
    end;
    
    methods
        function obj = OrderedMap(varargin)
            obj = obj@containers.Map(varargin{:});
            if length(varargin) > 0 && iscell(varargin{1})
                obj.keysInOrder = varargin{1}; % keys added as a keySet (cell of strings).
            end;
        end;

        
        function varargout = subsasgn(obj,s, B)
            switch s(1).type
                case '.'                   
                case '()'
                    varargout{1} = subsasgn@containers.Map(obj,s, B);
                    if iscell(s.subs) && length(s.subs) == 1
                        if ~any(strcmp(obj.keysInOrder, s.subs{1}))
                            obj.keysInOrder{end+1} = s.subs{1};
                        end;
                    end;
                case '{}'                   
            end
        end
        
        function obj = remove(mapObj,keySet)
            obj = remove@containers.Map(mapObj, keySet);
            
            % remove keys from keysInOrder property too.
            idMask = false(length(obj.keysInOrder), 1);
            for i=1:length(obj.keysInOrder)
                for j=1:length(keySet)
                    if isequal(obj.keysInOrder{i}, keySet{j})
                        idMask(i) = true;
                        break;
                    end;
                end;
            end;
            
            obj.keysInOrder(idMask) = [];
        end;
        
        function obj = vertcat(obj, obj2)
            objkeysInOrder = obj.keysInOrder;
            obj2keysInOrder = obj2.keysInOrder;
            
            keysOverwritten = intersect(objkeysInOrder, obj2keysInOrder);
            
            obj =  vertcat@containers.Map(obj, obj2);
            obj.keysInOrder = [setdiff(objkeysInOrder, keysOverwritten, 'stable') obj2keysInOrder];
            % the end result is that keys that are overwritten in obj2, disappear from the order
            % associated with obj and appear with the order as obj2
        end;
        
        function newObj = copy(obj, selectKeys)
            % newObj = copy(obj, selectKeys)
            % makes a new 'copy by value' copy of the map so e.g. changes inside a function does not affect the
            % map variable outside. 
            % if selectKeys is provided only these keys are copied.
            
            if isempty(obj)
                newObj = OrderedMap('UniformValues', false);
            else
                values = {};
                orderedKeys = obj.keysInOrder;
                
                if nargin > 1
                    orderedKeys = intersect(orderedKeys, selectKeys, 'stable');
                end;
                
                for i=1:length(orderedKeys)
                    values(i) = obj.values(orderedKeys(i));
                end;
                newObj = OrderedMap(orderedKeys, values, 'UniformValues', false);
            end;
        end
        
        function answer = isequal(a,b, useOrder)
            % answer = isequal(a,b, useOrder)
            if nargin < 3
                useOrder = false;
            end;
            
            answer = isequal(a.keys, b.keys) && isequal(a.values, b.values) && (~useOrder || isequal(a.keysInOrder, b.keysInOrder));
        end;
    end;
end