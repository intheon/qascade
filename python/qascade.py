import base64
import json
import yaml
import files_record

QASCADE_MANIFEST_FILE = 'manifest.qsc.yaml'

MATCH_DIRECTIVE = 'matches'
EXTRACT_DIRECTIVE = 'extract'
TABLE_DIRECTIVE = 'table'
NO_SUBDIR_DIRECTIVE = 'no-subdir'
VERSION_DIRECTIVE = 'qascade version'
IGNORE_DIRECTIVE = 'ignore'
# the (namespace) directive is processes like normal (key: value)s, hence not included

QASCADE_DIRECTIVES = [MATCH_DIRECTIVE, EXTRACT_DIRECTIVE, TABLE_DIRECTIVE, NO_SUBDIR_DIRECTIVE,
                      VERSION_DIRECTIVE, IGNORE_DIRECTIVE]


def files_and_folders(record, path=''):
    """
    Returns a tuple containing the lists of files and folders under 
    a certain path, from a Qascade record (as dictionary).
    
    :param record: qascade record
    :param path: path relative to the root of the Qascade container, empty refers to the root.     
    :return: the tuple (files, folders)
    """

    files = []
    folders = []

    # do not use / for the root
    path = path.lstrip('/')

    # include / at the end of the path if it is not there. Only for non-root paths
    if path and path[-1] != '/':
        path += '/'

    path_length = len(path)
    for fname in record['filenames']:
        if (len(fname) > path_length) and (path == '' or fname[0:path_length] == path):
            f = fname[path_length:]
            file_separator_location = f.find('/')
            if file_separator_location == -1:  # not found / so the file is not in a subfolder or a subfolder
                files.append(f)
            else:
                folders.append(f[0:file_separator_location])

    folders = list(set(folders))  # find unique folders.
    return files, folders


def get_file_content(filename, record):
    """
    Obtains the file content (in binary form) from the provided file record.
    Converts from Base64 encoded strings associated with files
    in 'file_contents' field of the record.
    
    :param filename: full file path, relative to the root of the container.
    :param record: files record dictionary
    :return: File content as binary.  
    """

    file_content = []

    # remove / before the text
    filename = filename.lstrip('/')

    if filename in record['file_contents'].keys():
        file_content = base64.b64decode(record['file_contents'][filename])
    else:
        print(filename + ' content does not exist ')

    return file_content


def _make_file_dicts(record, current_folder='', files_dict_array=None, parent_folder_manifest_dict=None, issues=None):

    """
    Reads/assigns raw (key:value) pairs to files in a given folder.
    Recursively goes into folders, reads qascade manifests (if existed) and places their content in file dictionaries.

    :param record: qascade file record
    :param current_folder: path relative to the root of the Qascade container, empty refers to the root. 
    :param files_dict_array: a dictionary that maps each filename (as provided in the record) to an array of 
                             dictionaries, each associated with a manifest file 
    
    :return: the tuple (files, folders)
    """

    if files_dict_array is None:
        files_dict_array = {}

    if issues is None:
        issues = []

    if isinstance(record, str):
        try:
            record = json.loads(record)
        except:
            print('Input record is not valid JSON.')
            return

    files, folders = files_and_folders(record, current_folder)  # get files and folders under the current folder
    current_folder_manifest_dict = None

    if QASCADE_MANIFEST_FILE in files:
        manifest_content = get_file_content(current_folder + '/' + QASCADE_MANIFEST_FILE, record)
        if not manifest_content:  # if manifest content has not been provided
            issues.append('Error: Missing content for ' + current_folder + '/' + QASCADE_MANIFEST_FILE
                          + ' file in files record.')
        else:                     # the manifest file is not empty
            current_folder_manifest_dict = yaml.load(manifest_content.decode('ascii'))
            print('folder:  ' + current_folder + ',  folder (keys-value)s:  ' + json.dumps(current_folder_manifest_dict))
            print('\n')

    for file in files:
        if file not in files_dict_array:
            files_dict_array[file] = []

        if parent_folder_manifest_dict is not None:
            files_dict_array[file].append(parent_folder_manifest_dict)

        if current_folder_manifest_dict is not None:
            files_dict_array[file].append(current_folder_manifest_dict)

    for folder in folders:
        print('\nProcessing folder: ' + folder)
        files_dict_array = _make_file_dicts(record, current_folder + '/' + folder, files_dict_array)

    return files_dict_array


def _process_manifest_keys(manifest_dict_array, issues=None):

    """
    Processes an array of dictionaries, each containing (key, value) pairs read from 
     one level of manifest files (a subfolder at any depth of the one before it). Applies Qascade directives in order
     and returns  

    :param manifest_dict_array: an array containing manifest dictionaries, in order (top folder first)
    :param issues: an array containing issues encountered      
    :return: the 'compiled' dictionary for the file
    """
    file_final_dict = {}
    for manifest_item in manifest_dict_array: # go over manifests in the array (each is a dictionary)
        for key in manifest_item:
            is_directive = False
            for directive in QASCADE_DIRECTIVES:
                if key.find('(' + directive) == 0 and key[-1] == ')':
                    is_directive = True
                    # code goes here
                    break

        if not is_directive:
            file_final_dict[key] = manifest_item[key]

    return file_final_dict

def process_record(record):
    files_dic_array = _make_file_dicts(record)
    files_final_dict = {}  # final output, with directives processed
    for file in files_dic_array:
        if not file.lower() == QASCADE_MANIFEST_FILE: # skip manifest files themselves
            files_final_dict[file] = _process_manifest_keys(files_dic_array[file])

    return files_final_dict


#folder = r'/home/nima/Documents/mycode/multi/qascade/unit_test/test2/container'
#files_record = create_files_record(folder, False)
# files, folders = files_and_folders(files_record, 'sub2')

#process_record(files_record)
# content = get_file_content('manifest.qsc.yaml', file_record)
# print(content.decode('ascii'))
# print(files)
# print(folders)