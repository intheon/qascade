import os
import base64
import json
import yaml

QASCADE_MANIFEST_FILE = 'manifest.qsc.yaml'

MATCH_DIRECTIVE = 'matches'
EXTRACT_DIRECTIVE = 'extract'
TABLE_DIRECTIVE = 'table'
NO_SUBDIR_DIRECTIVE = 'no-subdir'
VERSION_DIRECTIVE = 'qascade version'
IGNORE_DIRECTIVE = 'ignore'
# the (namespace) directive is processes like normal (key: value)s, hence not included

QASCADE_DIRECTIVES = [MATCH_DIRECTIVE, EXTRACT_DIRECTIVE, TABLE_DIRECTIVE, NO_SUBDIR_DIRECTIVE, VERSION_DIRECTIVE, IGNORE_DIRECTIVE]


def create_files_record(container_root_folder='', as_json=False):

    """
    Creates a 'files record' which consists of the list of all files under the root
    container folder (in 'filenames' key) and the contents of select files (in 
    'file_contents' key) encodes as Byte64.
    
    :param container_root_folder: A string specifying the Qascade container's folder.
    :param as_json: Whether to return the record in JSON format.
    :return: the 'files record' in dictionary or JSON format (see 'as_json' parameter)
    """
    files_record = {'filenames': [], 'file_contents': {}}
    for root, dirs, files in os.walk(container_root_folder, topdown=False):
         for name in files:
            root_relative_to_container = root[len(container_root_folder)+1:]
            filename_relative_to_container = os.path.join(root_relative_to_container, name)
            files_record['filenames'].append(filename_relative_to_container)
            full_filename = os.path.join(root, name)
            name_part, extension = os.path.splitext(name)
            if (extension in {'.tsv', '.xlsx'}) or name == 'manifest.qsc.yaml':
                read_bytes = open(full_filename, 'rb').read()
                read_bytes64 = base64.b64encode(read_bytes).decode('ascii')
                files_record['file_contents'][filename_relative_to_container] = read_bytes64

    if as_json:
        return json.dumps(files_record)
    else:
        return files_record


def files_and_folders(record, path=''):
    """
    Returns a tuple containing the lists of files and folders under 
    a certain path, from a Qascade record (as dictionary).
    
    :param path: path relative to the root of the Qascade container, empty refers to the root. 
    :param record: qascade record
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

def _process_manifest_keys(manifest_dict, files, current_folder='', files_dict=None, directives=None, issues=None):
    for manifest_key in manifest_dict:
        is_directive = False
        for directive in QASCADE_DIRECTIVES
            if manifest_key.find('(' + directive) == 0 and manifest_key[-1] == ')':
                is_directive = True
                # code goes here
                break

        if not is_directive:
            for file in files:
                # files_dict[file]['history'].append # add a record showing which directive in which
                                                   # manifest file overwrote which key
                files_dict[file]['key-values'][manifest_key] = manifest_dict[manifest_key]




def process_record(record, current_folder='', files_dict=None, file_directives=None, issues=None):

    if isinstance(record, str):
        try:
            record = json.loads(record)
        except:
            print('Input record is not valid JSON.')
            return

    files, folders = files_and_folders(record, current_folder)  # get files and folders under the current folder
    if QASCADE_MANIFEST_FILE in files:
        manifest_content = get_file_content(current_folder + '/' + QASCADE_MANIFEST_FILE, record)
        if not manifest_content:  # if it is empty
            issues.append('Error: Missing content for ' + current_folder + '/' + QASCADE_MANIFEST_FILE
                          + ' file in files record.')
        else:  # not empty
            manifest_dict = yaml.load(manifest_content.decode('ascii'))
            print(manifest_dict)

    for folder in folders:
        process_record(record, folder)



folder = r'/home/nima/Documents/mycode/multi/qascade/unit_test/test2/container'
files_record = create_files_record(folder, False)
# files, folders = files_and_folders(files_record, 'sub2')

process_record(files_record)
# content = get_file_content('manifest.qsc.yaml', file_record)
# print(content.decode('ascii'))
# print(files)
# print(folders)