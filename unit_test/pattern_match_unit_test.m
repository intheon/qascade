%% Standard pattern
cell_in = {'de_s1_feg_t1_hijk',...
    'abcde_s1_feg_t1_hijk',...
    'abcde_s2_feg_t1_hijk',...
    'abcde_s3_feg_t1_hijk',...
    'abcde_s1_feg_t2_hijk',...
    's1_feg_t2_hijk',...
    'feg_t2_hijk',...
    ''
    };
pattern = 'abcde_[subject]_feg_[task]_hijk';
cell_out = qascade_match(cell_in, pattern);
assert(isempty(cell_out{1}))
assert(strcmp(cell_out{2}('subject'),'s1'))
assert(strcmp(cell_out{2}('task'),'t1'))
assert(strcmp(cell_out{3}('subject'),'s2'))
assert(strcmp(cell_out{3}('task'),'t1'))
assert(strcmp(cell_out{4}('subject'),'s3'))
assert(strcmp(cell_out{4}('task'),'t1'))
assert(strcmp(cell_out{5}('subject'),'s1'))
assert(strcmp(cell_out{5}('task'),'t2'))
assert(isempty(cell_out{6}))
assert(isempty(cell_out{7}))
assert(isempty(cell_out{8}))



%% Key at the start of the pattern 
cell_in = {'de_s1_feg_t1_hijk',...
    'abcde_s1_feg_t1_hijk',...
    'abcde_s2_feg_t1_hijk',...
    'abcde_s3_feg_t1_hijk',...
    'abcde_s1_feg_hijk',...
    's1_feg_t2_hijk',...
    'feg_t2_hijk',...
    ''
    };
pattern = '[subject]_feg_[task]_hijk';
cell_out = qascade_match(cell_in, pattern);
assert(strcmp(cell_out{1}('subject'),'de_s1'))
assert(strcmp(cell_out{1}('task'),'t1'))
assert(strcmp(cell_out{2}('subject'),'abcde_s1'))
assert(strcmp(cell_out{2}('task'),'t1'))
assert(strcmp(cell_out{3}('subject'),'abcde_s2'))
assert(strcmp(cell_out{3}('task'),'t1'))
assert(strcmp(cell_out{4}('subject'),'abcde_s3'))
assert(strcmp(cell_out{4}('task'),'t1'))
assert(isempty(cell_out{5}))
assert(strcmp(cell_out{6}('subject'),'s1'))
assert(strcmp(cell_out{6}('task'),'t2'))
assert(isempty(cell_out{7}))
assert(isempty(cell_out{8}))

%% Key at the end of the pattern 
cell_in = {'de_s1_feg_t1_hijk',...
    'abcde_s1_feg_t1_hijk',...
    'abcde_s2_feg_t1_hijk',...
    'abcde_s3_feg_t1_hijk',...
    'abcde_s1_feg_t2_hijk',...
    's1_feg_t2_hijk',...
    'feg_t2_hijk',...
    ''
    };
pattern = '[subject]_feg_[task]';
cell_out = qascade_match(cell_in, pattern);
assert(strcmp(cell_out{1}('subject'),'de_s1'))
assert(strcmp(cell_out{1}('task'),'t1_hijk'))
assert(strcmp(cell_out{2}('subject'),'abcde_s1'))
assert(strcmp(cell_out{2}('task'),'t1_hijk'))
assert(strcmp(cell_out{3}('subject'),'abcde_s2'))
assert(strcmp(cell_out{3}('task'),'t1_hijk'))
assert(strcmp(cell_out{4}('subject'),'abcde_s3'))
assert(strcmp(cell_out{4}('task'),'t1_hijk'))
assert(strcmp(cell_out{5}('subject'),'abcde_s1'))
assert(strcmp(cell_out{5}('task'),'t2_hijk'))
assert(strcmp(cell_out{6}('subject'),'s1'))
assert(strcmp(cell_out{6}('task'),'t2_hijk'))
assert(isempty(cell_out{7}))
assert(isempty(cell_out{8}))

%% Change in the subject key
cell_in = {'de_s1_feg_t1_hijk',...
    'abcde_s1_feg_t1_hijk',...
    'abcde_s2_feg_t1_hijk',...
    'abcde_s3_feg_t1_hijk',...
    'abcde_s1_feg_t2_hijk',...
    's1_feg_t2_hijk',...
    'feg_t2_hijk',...
    ''
    };
pattern = 'abcde_[condition]_feg_[task]_hijk';
cell_out = qascade_match(cell_in, pattern);
assert(isempty(cell_out{1}))
assert(strcmp(cell_out{2}('condition'),'s1'))
assert(strcmp(cell_out{2}('task'),'t1'))
assert(strcmp(cell_out{3}('condition'),'s2'))
assert(strcmp(cell_out{3}('task'),'t1'))
assert(strcmp(cell_out{4}('condition'),'s3'))
assert(strcmp(cell_out{4}('task'),'t1'))
assert(strcmp(cell_out{5}('condition'),'s1'))
assert(strcmp(cell_out{5}('task'),'t2'))
assert(isempty(cell_out{6}))
assert(isempty(cell_out{7}))
assert(isempty(cell_out{8}))
