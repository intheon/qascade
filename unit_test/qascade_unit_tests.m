
% for testing, there must be a folder named 'container' and a file named 'correct_read.yaml' in each
% test folder,'qascade/unit_test'

path = fileparts(mfilename('fullpath'));
d = dir(path);
for i=3:length(d)
    if d(i).isdir
        filekvs = nestd_cell_string_to_cell_string(qascade_read([path filesep d(i).name filesep 'container'])); 
         %WriteYaml([path filesep d(i).name filesep 'correct_read.yaml'], filekvs);
        correctFilekvs = nestd_cell_string_to_cell_string(ReadYamlRawMap([path filesep d(i).name filesep 'correct_read.yaml']));
                
        if ~isequal(filekvs, correctFilekvs) && isequal(filekvs.keys, correctFilekvs.keys)
            fprintf('Files are the same.\n');
            
            keys = filekvs.keys;
            for j=1:length(keys)
                if ~isequal(filekvs(keys{j}), correctFilekvs(keys{j}))
                    fprintf('(keys:values) for file ''%s'' differ.\n', keys{j});
                    if isequal(filekvs(keys{j}).keys, correctFilekvs(keys{j}).keys)
                        fprintf('   Keys are the same.\n');
                        keys2 = filekvs(keys{j}).keys;
                        v1 = filekvs(keys{j}).values;                      
                        v2 = correctFilekvs(keys{j}).values;                      
                        for k=1:length(v1)
                            if ~isequal(v1{k}, v2{k})
                                fprintf('   Values of key ''%s'' differs:', keys2{k});
                                fprintf('\nRead:  ');
                                disp(v1{k});
                                fprintf('Correct: ');
                                disp(v2{k});                                
                            end;
                        end
                    else
                        fprintf('   Keys are different: \n');
                        fprintf('\nRead:   ');
                        disp(filekvs(keys{j}).keys);                      
                        fprintf('Correct:');
                        disp(correctFilekvs(keys{j}).keys);
                    end;
                end;
            end;
            
        end;
        
        if isequal(filekvs, correctFilekvs)
            fprintf('Unit test passed for container ''%s''.\n', d(i).name);
        end;
        
    end;
end;
