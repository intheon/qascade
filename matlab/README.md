# MATLAB implementation of Qascade reader

This folder contains an implementation of Qascade reader in MATLAB. 

**Note:** This implementation should *not* currently be considered the reference implemnetation since the`(extract)` directives always overwrite keys assigned by `(match)` directives (in the same level/folder) in its output but according to Qascade schema, directive must be applied based on their order (no matter what their type is). However, for most use cases this may not make a difference. We plan to release a reference implementation whose behavior fully adheres to the Qascade schema.

## How to use

The main function is `qascade_read()` which is pointed to the root Qascade container and outputs a number of ("key": value) pairs along with an array containing any potential issues encountered:

```
[filesMapToKeyValues, issues] = qascade_read(rootfolder)
```

The output `filesMapToKeyValues` is a MATLAB variable of type container.Map with one key per file path. These file paths are relative to the root container folder with file separators in the format required by the OS on which the function is running, i.e. \ for Windows and / for Linux. The value associated with each of these file paths is also of type container.Map and contains ("key": value) pairs assigned to that file by Qascade.

The companion utility function `qascade_find()` enables querying for files that contain a certain key (or subkey).

