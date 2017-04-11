function list  = match_glob(fileList, filespec)

if strncmp(filespec, '/', 1)
    % FILESPEC specifies a absolute path
    pathroot = '/';
    filespec(1) = [];
elseif ispc && numel(filespec)>=2 && filespec(2)==':'
    % FILESPEC specifies a absolute path starting with a drive letter
    % check for a fileseparator after ':'. e.g. 'C:\'
    if numel(filespec)<3 || filespec(3)~='/'
        error('glob:invalidInput','Drive letter must be followed by '':\''.')
    end
    pathroot = filespec(1:3);
    filespec(1:3) = [];
else
    % FILESPEC specifies a relative path
    pathroot = './';
end


%% replace multiple file separators by a single file separator
filespec = regexprep(filespec, '/+', '/');

%% replace 'a**' with 'a*/**', where 'a' can be any character but not '/'
filespec = regexprep(filespec, '([^/])(\.\*\.\*)', '$1\*/$2');
%% replace '**a' with '**/*a', where a can be any character but not '/'
filespec = regexprep(filespec, '(\.\*\.\*)([^/])', '$1/\*$2');

%% split filespec into chunks at file separator
chunks = strread(filespec, '%s', 'delimiter', '/'); %#ok<FPARK>

%% add empty chunk at the end when filespec ends with a file separator
if ~isempty(filespec) && filespec(end)=='/'
    chunks{end+1} = '';
end

%% translate chunks to regular expressions
for i=1:numel(chunks)
    chunks{i} = glob2regexp(chunks{i});
end

%% determine file list using LS_REGEXP
% this function requires that PATHROOT does not to contain any wildcards
if ~isempty(chunks)
    list = ls_regexp(@regex, fileList, chunks{1:end});
else
    list = fileList;
end


function regexp_str = glob2regexp(glob_str)
%% translate glob_str to regular expression string

% initialize
regexp_str  = '';
in_curlies  = 0;        % is > 0 within curly braces

% handle characters in glob_str one-by-one
for c = glob_str
    
    if any(c=='.()|+^$@%')
        % escape simple special characters
        regexp_str = [regexp_str '\' c]; %#ok<AGROW>
        
    elseif c=='*'
        % '*' should not match '/'
        regexp_str = [regexp_str '[^/]*']; %#ok<AGROW>
        
    elseif c=='?'
        % '?' should not match '/'
        regexp_str = [regexp_str '[^/]']; %#ok<AGROW>
        
    elseif c=='{'
        regexp_str = [regexp_str '(']; %#ok<AGROW>
        in_curlies = in_curlies+1;
        
    elseif c=='}' && in_curlies
        regexp_str = [regexp_str ')']; %#ok<AGROW>
        in_curlies = in_curlies-1;
        
    elseif c==',' && in_curlies
        regexp_str = [regexp_str '|']; %#ok<AGROW>
        
    else
        regexp_str = [regexp_str c]; %#ok<AGROW>
    end
end

% replace original '**' (that has now become '[^/]*[^/]*') with '.*.*'
regexp_str = strrep(regexp_str, '[^/]*[^/]*', '.*.*');

function L = ls_regexp(regexp_fhandle, fileList, varargin)
% List files that match PATH/r1/r2/r3/... where PATH is a string without
% any wildcards and r1..rn are regular expresions that contain the parts of
% a filespec between the file separators.
% L is a cell array with matching file or directory names.
% REGEXP_FHANDLE contain a file handle to REGEXP or REGEXPI depending
% on specified case sensitivity.


% get contents of path
for i=1:length(list)
    list.name = fileList;

if nargin>=3
    if strcmp(varargin{1},'\.') || strcmp(varargin{1},'\.\.')
        % keep explicitly specified '.' or '..' in first regular expression
        if ispc && ~any(strcmp({list.name}, '.'))
            % fix strange windows behaviour: root of a volume has no '.' and '..'
            list(end+1).name = '.';
            list(end).isdir = true;
            list(end+1).name = '..';
            list(end).isdir = true;
        end
    else
        % remove '.' and '..'
        list(strcmp({list.name},'.')) = [];
        list(strcmp({list.name},'..')) = [];
        
        % remove files starting with '.' specified in first regular expression
        if ~strncmp(varargin{1},'\.',2)
            % remove files starting with '.' from list
            list(strncmp({list.name},'.',1))  = [];
        end
    end
end

% define shortcuts
list_isdir = [list.isdir];
list_name = {list.name};

L = {};  % initialize
if nargin==2    % no regular expressions
    %% return filename
    if ~isempty(list_name)
        % add a trailing slash to directories
        trailing_fsep = repmat({''}, size(list_name));
        trailing_fsep(list_isdir) = {'/'};
        L = strcat(path, list_name, trailing_fsep);
    end
    
elseif nargin==3    % last regular expression
    %% return list_name matching regular expression
    I = regexp_fhandle(list_name, ['^' varargin{1} '$']);
    I = ~cellfun('isempty', I);
    list_name = list_name(I);
    list_isdir = list_isdir(I);
    if ~isempty(list_name)
        % add a trailing slash to directories
        trailing_fsep = repmat({''}, size(list_name));
        trailing_fsep(list_isdir) = {'/'};
        L = strcat(path, list_name, trailing_fsep);
    end
    
elseif nargin==4 && isempty(varargin{2})
    %% only return directories when last regexp is empty
    % return list_name matching regular expression and that are directories
    I = regexp_fhandle(list_name, ['^' varargin{1} '$']);
    I = ~cellfun('isempty', I);
    % only return directories
    list_name = list_name(I);
    list_isdir = list_isdir(I);
    if any(list_isdir)
        % add a trailing file separator
        L = strcat(path, list_name(list_isdir), '/');
    end
else
    %% traverse for list_name matching regular expression
    I = regexp_fhandle(list_name, ['^' varargin{1} '$']);
    I = ~cellfun('isempty', I);
    for name = list_name(I)
        L = [L   ls_regexp(regexp_fhandle, [path char(name) '/'], varargin{2:end})]; %#ok<AGROW>
    end
end


