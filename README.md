# working with ini files without complication, keep its comments, blank lines and formats!

NOTE>  Section and keys MUST NOT contains spaces!

## Features

Now you can read and write your ini files and when you save it, you will keep all contents like blank lines, comments and formats.
This package will respect not only the comments started with ; or #, but any lines that are not sections or keys!
The section items can be returned in array of strings or json format!

# Installing

Add `IniFile` to your pubspec.yaml file:

```yaml
dependencies:
  ini_file:
```

Import `IniFile` in files that it will be used:

```dart
import 'package:ini_file/ini_file.dart';
```

## Getting started

Just create an instance of `IniFile` and start working:
```dart
    IniFile ini = IniFile();
    await ini.readFile('./example/YSA.ini');
    print(ini.getItems('SETTINGS'));

    // the lines above will produce this awesome outputs!
    [[caps, 1], [ignore, true]]
    {SETTINGS: {caps: 1, ignore: true}}

```


## Usage

```dart
import 'package:ini_file/ini_file.dart';

    // create the instance
    IniFile ini = IniFile();

    // load ini file contents
    await ini.readFile('./example/YSA.ini');

    // get items of an entire section
    print(ini.getItems('SETTINGS'));

    // get specific item inside a section
    print(ini.getItem('SETTINGS', 'caps'));

    // modifying existing item
    ini.setItem('SETTINGS', 'caps', '2');

    // creating new item
    ini.setItem('SETTINGS', 'debug', 'false');
    
    // inserting items in section
    ini.setItems('SETTINGS', [
        ['abc', '1'],
        ['def', '2']
    ]);

    // removing entire section
    // note that removing entire section will also remove
    // the comments above the section until a blank line 
    // or valid line was found
    ini.removeSection('SETTINGS');

    // creating new section/item
    // if the section does not exists, it will be created
    // the same rule applies to keys
    ini.setItem('NEWSECTION', 'newitem', 'new value');

```

## Additional information

**Show some ❤️ and star the repo to support the project**

