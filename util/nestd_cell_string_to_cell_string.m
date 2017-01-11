function out = nestd_cell_string_to_cell_string(input)
% out = nestd_cell_string_to_cell_string(input)
%  If input is a cell array containing cell arrays of strings
%  it converts it to a single cell array of string.
%  if input is a map, it recursively runs this conversion on all its values.

out = input;
if iscell(input) && all(cellfun(@iscell, input)) && all(cellfun(@(x) ischar(x{1}), input))
    out = cell(length(input), 1);
    for i=1:length(input)
        out{i} = input{i}{1};
    end;
elseif isa(input, 'containers.Map')
    keys = input.keys;
    for i=1:length(keys)
        input(keys{i}) = nestd_cell_string_to_cell_string(input(keys{i}));
    end;    
end

