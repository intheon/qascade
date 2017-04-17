import os

qascade_record = {'filenames': [], 'file_contents': {}}
container_root_folder = r'C:\Users\Nima\Documents\MATLAB\tools\qascade\matlab\unit_test\test2\container'
for root, dirs, files in os.walk(container_root_folder, topdown=False):
     for name in files:
        root_relative_to_container = root[len(container_root_folder)+1:]
        # print(os.path.join(root_relative_to_container, name))
        qascade_record['filenames'].append(os.path.join(root_relative_to_container, name))
        full_filename = os.path.join(root, name)
        name_part, extension = os.path.splitext(name)
        if (extension in {'.tsv', '.xlsx'}) or name == 'manifest.qsc.yaml':
            print(name)
            read_bytes = open(full_filename, 'rb').read()
            print(read_bytes)


# print(qascade_record['filenames'])
