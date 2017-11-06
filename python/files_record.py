import os
import base64
import json

QASCADE_MANIFEST_FILE = 'manifest.qsc.yaml'


def create_files_record(container_root_folder='', as_json=False):
    """
    Creates a 'files record' which consists of the list of all files under the root
    container folder (in 'filenames' key) and the contents of select files (in 
    'file_contents' key) encoded as Byte64.

    :param container_root_folder: A string specifying the Qascade container's folder.
    :param as_json: Whether to return the record in JSON format.
    :return: the 'files record' in dictionary or JSON format (see 'as_json' parameter)
    """
    files_record = {'filenames': [], 'file_contents': {}}
    for root, dirs, files in os.walk(container_root_folder, topdown=False):
        for name in files:
            root_relative_to_container = root[len(container_root_folder) + 1:]
            filename_relative_to_container = os.path.join(root_relative_to_container, name)
            files_record['filenames'].append(filename_relative_to_container)
            full_filename = os.path.join(root, name)
            name_part, extension = os.path.splitext(name)
            if (extension in {'.tsv', '.xlsx'}) or name == QASCADE_MANIFEST_FILE:
                read_bytes = open(full_filename, 'rb').read()
                read_bytes64 = base64.b64encode(read_bytes).decode('ascii')
                files_record['file_contents'][filename_relative_to_container] = read_bytes64

    if as_json:
        return json.dumps(files_record)
    else:
        return files_record