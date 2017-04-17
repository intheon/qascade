import os
import base64
import json

qascade_record = {'filenames': [], 'file_contents': {}}
container_root_folder = r'C:\Users\Nima\Documents\MATLAB\tools\qascade\matlab\unit_test\test2\container'
for root, dirs, files in os.walk(container_root_folder, topdown=False):
     for name in files:
        root_relative_to_container = root[len(container_root_folder)+1:]
        filename_relative_to_container = os.path.join(root_relative_to_container, name)
        # print(os.path.join(root_relative_to_container, name))
        qascade_record['filenames'].append(filename_relative_to_container)
        full_filename = os.path.join(root, name)
        name_part, extension = os.path.splitext(name)
        if (extension in {'.tsv', '.xlsx'}) or name == 'manifest.qsc.yaml':
            # print(name)
            read_bytes = open(full_filename, 'rb').read()
            read_bytes64 = base64.b64encode(read_bytes).decode('ascii')
            # print(read_bytes64)
            qascade_record['file_contents'][filename_relative_to_container] = read_bytes64

print(json.dumps(qascade_record))
