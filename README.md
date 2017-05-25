# Qascade: Cascading File Keys

_Copyright © 2016-2017 Syntrogi (dba Qusp)_

> When you first start off trying to solve a problem, the first solutions you come up with are very complex, and most people stop there. But if you keep going, and live with the problem and peel more layers of the onion off, you can often times arrive at some very elegant and simple solutions. -Steve Jobs

Changelog:

- 3/16/2017, version 1.2.0, added (namespace) and (ignore) directives.
- 3/13/2017: version 1.1.0, added external folders in spreadsheet (e.g. Excel) format.
- 3/8/2017: version 1.0.0, added (extract) directive and external tables.
- 2/1/2017: version 0.2.1 named changed from CFK to Qascade.
- 12/27/2016, version 0.2.0: adding folder matching and inline tables.
- 12/9/2016, version 0.1.0, first draft.

## Background

Assigning meta-data to individual files located on a conventional file system is a basic operation required for most (if not all) containerization/packaging systems, such as ESS, BIDS and ISA-TAB. This operation can be reformulated as assigning a number of (key: value) pairs to each file. Containerization systems differ in (a) their controlled vocabulary (b) the way they encode (key: value) pairs (ESS uses XML, BIDS uses JSON and ISA-TAB uses tab-separated files) (c) how they require files to be organized in subfolders.

The prescribed organization of the files is often selected to maximally map to the main concepts in the field, e.g. session in EEG studies (ESS) and Runs in fMRI (BIDS). Another way to look at this organization is to treat it as an optimal factorization, e.g. to use folder structure in a way that files sharing the most meta-data keys are placed under the same folder.

Inspired by this principle and other commonalities across study containerization standards, Qascade "meta containerization" system provides a generalized interface for assigning (key: value) pairs to files. The main emphasis of Qascade is user convenience and lowering of the barriers to entry. Similar to BIDS, Qascade uses the file system and simple text files as its primary user-interface.

## Specification

The main idea behind the Qascade is simple: at each level of a file hierarchy, a special "manifest.qsc.yaml" file (containing YAML or JSON text) is placed which contains (key:value) pairs that are assigned to all files in the folder and its subfolders. Manifest files in subfolders overwrite keys assigned in parent directories:

[image here]

## Selective Overwrite

For keys whose values have fields, e.g. JavaScript objects, the dot "." notation, as in keyx.fieldy, is interpreted as a request to overwrite fieldx field of keyx, keeping other fields in the key, specified in the parent level, intact. Regular keys hence must not contain dots (since they will be interpreted as overwrite directives). Nested fields can be overwritten as keyx.fieldy.fieldz. When a field whose subfield is referenced in an overwrite directive is not present, it will be created, e.g. if the key keyx does not have fieldy (but has other fields), the field fieldy will be created.

If a key is is not of structure type (does not have fields, e.g. a numerical or string array), then a warning is produced by Qascade interpreter and the overwrite is not applied. Selective overwrite may be used in combination with directives, e.g. in (matches) and (table) directives.

## Directives

Directive are special key names that are interpreted differently by Qascade to provide a number of functionalities. These directives are often not assigned verbatim as key:value pairs. However, similar to other keys:value, they are inherited to subfolder, and may be overwritten by manifest files inside subfolders. File and Folder matching

Individual files, folders, file-patterns and folder patterns (e.g. wildcards), may be assigned directly to (key: value) pairs in manifest files. This is achieved via the use of (matches) directive:

```
(matches 200_Hz/*.xml)
   key 1: value 1
   key 2: value 2

(matches *.m):
   key 1: value 3
   key 3: value 4

(matches abc.xyz):
   key 2: value 5
   key 4: value 6
```

Any keys with the format `(matches some_pattern)` is interpreted this way. The matching pattern should follow GNU/Linux Standard Wildcards (i.e. globbing patterns, see here) and can match files, folders or combination of file and folders. Folder aboves the root folder of the container are excluded in file paths during this match process in order to make Qascade containers portable (result in the same behaviour regardless of their location in the user file system).

Folder matching enables the efficient use of folders to set particular key values, e.g. all recordings files with the same sampling rate can be placed in "256 Hz" subfolder, or data from normal and patient groups placed under subfolder with these names.

When multiple fields are present under Qascade-match-file (files, folders or tables), any match to one of them will inherit the (key: value) pairs assigned under it. File matches have precedence over folder matches.

### Key-value extraction from folder and filenames

`(key: value)` pairs can be extracted directly from file and folder names via the use of (extract) directive:

```
(extract sometitle_S[subjectNumber]_T[taskLabel].*): direct
```

This matches all files that adhere to the above pattern and extracts values for the specified keys, `subjectNumber` and `taskLabel`, which are enclosed in [ ]:

Resulting for the file: sometitle_S56_Teyes-open.*

```
   subjectNumber: '56'
   taskLabel: eyes-open
```

The wildcard character '*' can be used to match an arbitrary-length string. The direct value assigned to the `(extract)` directive above means that the extracted values are directly assigned to keys. Keys can alternatively be assigned after applying a mapping specified as the value to the `(extract)` directive, for example:

```
(extract sometitle_S[subjectNumber]_T[taskLabel].*):
      taskLabel:
              r: resting
              ec: eyes-closed
              eo: eyes-open
```

Results for the file sometitle_S56_Tec.*

```
   subjectNumber: '56'
   taskLabel: eyes-closed
```

All key values, including numbers, are extracted as strings. When mapping numbers to other values, they must be explicitly indicated as strings, e.g.

```
(extract sometitle_S[subjectNumber]_T[taskLabel].set):
      subjectNumber:
              '123': 1230000
```

Only extraction patterns that contain the '/' character are compared against full paths (relative to container root folder). If '/' is placed at the end, the pattern is assumed to be a folder (similar to '/*') and hence to match all files in the folder (including subfolders). For example:

```
(extract subject[subjectNumber]/): direct
```

will assign (subjectNumber: '5') to all the files in subject5/ folder.

### Named Tables

Tab-separated value (TSV) tables can be placed in Qascade manifest file under (table) directive, as a way to compactly assign values to individual files or wildcard patterns of file and folders. They can also be placed in a separate file pointed to using this directive.

In Qascade TSV tables, the first row must contain the keys, starting with (match) directive indicating the subsets of files the following keys are assigned to. Keys and values must be separated by a tab character. If there are multiple tables present in a manifest file, each table needs to have a unique name, included as (table name). Example for a single table in the manifest file:

```
(table): |
                (match)    key1    key2
                 *.m    value1     value2
                 File1.set    value3      value4
```

Example for multiple tables in a manifest file:

```
(table abc): |
                (match)    key1    key2
                 *.m    value1     value2
                 File1.set    value3      value4

(table xyz): |
                (match)    key10    key20
                 *.txt    value10     value20
                 group\    value30      value40
```

External tables (table content in a different file) can be specified as:

```
(table xyz): [filename, with a path relative to the manifest file]
```

e.g.

```
(table xyz): fileSubjects.tsv
```

when the table is in the same folder as the manifest file, or

```
(table xyz): /tables/fileSubjects.tsv
```

when it is in the tables/ folder, under the folder containing the manifest file. Supported format for tables are .tsv (tab separated values) or spreadsheet formats (.xls, .xlsx, .xlsb, .xlsm, .xltm, .xltx, .ods). If the external table is a spreadsheet, variable names must be placed on the first row (there should be no empty rows above the table) and the first column of the table should be the first column of the spreadsheet (there should be no empty columns on the left side of the table).

### Folder-only keys

By default Qascade propagates (key:value) pairs from each folder to all of its subfolders. (no-subdir) directive prevents this behavior for as subset of (key:value) pairs defined under it:

```
(no-subdir):
   folderOnlyKey: somevalue # this is not applied to subfolders
```

Other directive can be placed under (no-subdir) and will only apply to files in the folder (and not subfolders):

```
(no-subdir):
   folderOnlyKey: somevalue # these are not applied to subfolders
   (matches *.m):
      Key1: values 1
   (table):
       (match)    key10    key20
         *.txt    value10     value20
          group\    value30    value40
```

The key:value pairs assigned under (no-subdir) take precedence over the ones assigned outside it.

### Qascade version

It is highly suggested that the version of the Qascade schema to which a manifest file adheres to be specified using the (qascade version) directive, as:

`(qascade version): 1.0.1`

This enables parsers to process file according to the appropriate version of the schema. Qascade uses Semantic Versioning 2.0.0 (<http://semver.org/>).

### Namespace

The namespace for the vocabulary of keys:value pairs used in a Qascade manifest may be specified using the (namespace) directive, e.g. :

`(namespace): eegstudy.org`

This is similar to XML namespaces. Unlike other directives, the (namespace) directive is interpreted like other keys and assigned to all files to which it applies.

### Ignoring files

You can exclude some files from being processed as a part of the Qascade container using the (ignore) directive (similar to gitignore in Git). Qascade parsers will not include these ignored files in the list of files for which key: values are returned. Similar to (match) directive, (ignore) directive accepts wildcard patterns for files and folders, e.g.:

`(ignore): *.atk`

ignores all the files with extension .atk.

## Important Notes

in Qascade manifest files, all specified paths must use unix-style folder separator '/. This is to ensure uniform execution across platforms'. Windows-style folder separator '\' will be parsed incorrectly in YAML. Each directive is initially read as a YAML (key:variable) pair and since YAML readers only return the last value assigned to each key, you should only use a single directive phrase once in each manifest document. For example:

```
(match *.m):
    a: true
…
(match *.m):
    b: true
```

will only assign b: true to .m files and ignores the first match expression. You should instead group these together:

```
(match *.m):
    a: true
    b: true
```

```
the same rule applies to other directive, e.g. (extract).
```

Directives from higher level folders are executed before subsequent, For example if we have the following directive at folder /f1

```
(match *.set):
   a: 1
   b: 2
```

and have in folder /f1/f2

```
(match *.set):
   a: 10
```

then all *.set files will have {a:10, b:2}.

## Usage

Qascade may be used as the first step of placing files in ESS/BIDS, etc. a Qascade parser will traverse the folder structure, starting from a root folder, and return a flat list of files (including their full path), as keys, each associated with an array of (key: value) pairs for the file. The output can then be used by ESS/BIDS/.. applications to place the data into domain-specific containers:

### Comparison of ESS Level 1 XML container and ESS Level 1 Qascade:
