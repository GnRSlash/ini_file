import 'dart:convert';
import 'dart:io';

/// class to work with ini files and keep all comments and formats
class IniFile {
  late File _file;
  Encoding _encoding = utf8;
  List<String> _lines = [];

  /// if you want spaces to be removed from the results, set this to true
  bool trimResults;

  /// keep tracking of sections to improve search
  final List<String> _sections = [];
  final RegExp _sectionPattern = RegExp(r'^[^#;\s]+[\[\]]', multiLine: true);
  final RegExp _entryPattern = RegExp(r'^([^#;\s]+)([\s]*)=(.*?)$', multiLine: true);

  IniFile({this.trimResults = true});

  /// create a new empty file
  /// throws exceptions
  factory IniFile.emptyFile(String filePath, {bool trimResults = true, bool overrideFile = false}) {
    File file = File(filePath);
    if (file.existsSync()) {
      if (overrideFile) {
        file.delete();
      } else {
        throw Exception('File already exists!');
      }
    }
    file.writeAsStringSync('# Created by ini_file dart package!');

    IniFile newini = IniFile(trimResults: trimResults);
    newini._file = File(filePath);
    return newini;
  }

  /// opens the file and read all lines
  /// throws exceptions for any fail
  Future<void> readFile(String filePath, {Encoding encoding = utf8}) async {
    File file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found!');
    }
    _lines = await file.readAsLines(encoding: encoding);
    _readSections(await file.readAsString());
    _encoding = encoding;
    _file = file;
  }

  /// write the ini contents to the original file
  /// throws exceptions if it fails
  Future<void> writeFile([String? saveAsFilePath]) async {
    File file = _file;
    if (saveAsFilePath != null) {
      file = File(saveAsFilePath);
    }
    await file.writeAsString(toString(), mode: FileMode.writeOnly, encoding: _encoding);
  }

  /// get section items and convert to Map format (use json.decode(json.encode(this)) to get json format)
  /// section is case insensitive
  Map<String, Map<String, String>> getJsonItems(String section) {
    Map<String, Map<String, String>> ret = {section: {}};
    List<List<String>> items = getItems(section);
    for (List<String> item in items) {
      ret[section]?.addAll({item[0]: item[1]});
    }
    return ret;
  }

  /// get section items and returns in list of list items
  /// section is case insensitive
  List<List<String>> getItems(String section) {
    return _getKeysOrKey(section);
  }

  /// get just one key from section
  /// section and key are case insensitive
  /// returns null if item was not found
  String? getItem(String section, String key) {
    List<List<String>> items = _getKeysOrKey(section, key);

    return items.isEmpty ? null : items[0][1];
  }

  /// change existing key in section or create new key and new section if they don't exist
  /// section and key are case insensitive
  /// this function can throws exceptions
  void setItem(String section, String key, String value) {
    if (key.contains(' ') || section.contains(' ')) {
      throw ('Sections and Keys must not contain spaces!');
    }
    setItems(section, [
      [key, value]
    ]);
  }

  /// write to an existing section item (create the item if it not exists)
  void setItems(String section, List<List<String>> values) {
    if (section.contains(' ')) {
      throw ('Sections and Keys must not contain spaces!');
    }
    int firstSectionLine = _getOrCreateSection(section);
    int line = firstSectionLine;
    Map<String, String> items = _listToMap(values);

    while (line < _lines.length) {
      if (_entryPattern.hasMatch(_lines[line])) {
        List<String> splits = _lines[line].split('=');
        if (items.containsKey(splits[0].trim().toLowerCase())) {
          _lines[line] = '${splits[0].trim()}=${items[splits[0].trim().toLowerCase()]}';
          items.remove(splits[0].trim().toLowerCase());
        }
      }
      if (_sectionPattern.hasMatch(_lines[line]) || items.isEmpty) {
        // section does not contains this key
        break;
      }
      line++;
    }

    // insert new keys if they were not changed
    line = firstSectionLine;
    items.forEach((key, value) {
      _lines.insert(line, '$key=$value');
      line++;
    });
  }

  /// delete entire section if it exists
  /// section is case insensitive
  void removeSection(String section) {
    int start = 0;
    int end = 0;
    int line = 0;
    if (!_sections.contains(section)) {
      return;
    }
    _sections.remove(section.toLowerCase());
    while (line + 1 < _lines.length) {
      if (_sectionPattern.hasMatch(_lines[line])) {
        if (start != 0) {
          // reach the end of section
          end = line;
          break;
        }
        if (_sectionPattern.stringMatch(_lines[line])?.toLowerCase() == '[${section.toLowerCase()}]') {
          start = line;
        }
      }
      line++;
    }
    if (end != 0) {
      // need to go back to keep comments of next section
      while (end > start) {
        if (_entryPattern.hasMatch(_lines[end - 1])) {
          break;
        }
        end--;
      }
      // need to go back to remove comments of this section
      while (start > 0) {
        if (_entryPattern.hasMatch(_lines[start - 1]) || _lines[start].trim().isEmpty) {
          break;
        }
        start--;
      }
      _lines.removeRange(start, end);
    }
  }

  /// returns a list of all sections found in this file
  List<String> getAllSections() {
    return _sections;
  }

  /// get all contents (except comments and blank lines) as Map format
  /// (use json.decode(json.encode(this)) to get as json format)
  Map<String, dynamic> toMap() {
    Map<String, dynamic> ret = {};

    for (String section in _sections) {
      ret[section] = getJsonItems(section);
    }

    return ret;
  }

  @override

  /// returns all the file contents
  String toString() {
    return _lines.join('\r\n');
  }

  /// convert List<List<String>> into Map<String, String>
  /// all keys will be converted to lowerCase
  Map<String, String> _listToMap(List<List<String>> items) {
    Map<String, String> ret = {};
    for (List<String> item in items) {
      ret[item[0].trim().toLowerCase()] = _trimItem(item[1]);
    }
    return ret;
  }

  /// put all existing sections inside a control variable
  /// to make checks faster
  void _readSections(String contents) {
    RegExp pattern = RegExp(r'^[^#;\s]+[\[\]]', multiLine: true);
    Iterable<RegExpMatch> items = pattern.allMatches(contents);
    for (RegExpMatch element in items) {
      _sections.add(contents.substring(element.start + 1, element.end - 1).toLowerCase());
    }
  }

  /// create a new section (if it not exists)
  /// returns the next line number of the section
  int _getOrCreateSection(String section) {
    if (!_sections.contains(section.toLowerCase())) {
      _sections.add(section.toLowerCase());
      if (!_lines.isEmpty && _lines[_lines.length - 1].trim().isNotEmpty) {
        _lines.add('');
      }
      _lines.add('[$section]');
      return _lines.length;
    }
    return _getSection(section);
  }

  /// return next line number of the section
  /// throws exception
  int _getSection(String section) {
    section = section.toLowerCase();
    for (int i = 0; i < _lines.length; i++) {
      if ((_sectionPattern.stringMatch(_lines[i]) ?? '').toLowerCase() == '[$section]') {
        return i + 1;
      }
    }
    throw Exception("can't create section, internal error!");
  }

  /// get all section items, or just one item if specified by key
  List<List<String>> _getKeysOrKey(String section, [String key = '']) {
    List<List<String>> ret = [];
    bool inSection = false;
    section = section.toLowerCase();
    for (String item in _lines) {
      if (_sectionPattern.hasMatch(item)) {
        if (inSection) {
          break;
        }
        inSection = _sectionPattern.stringMatch(item)?.toLowerCase() == '[$section]';
      }
      if (inSection && _entryPattern.hasMatch(item)) {
        List<String> items = item.split('=');
        if (items[0].trim().toLowerCase() == key.toLowerCase()) {
          return [
            [items[0].trim(), _trimItem(items[1])]
          ];
        }
        ret.add([items[0].trim(), _trimItem(items[1])]);
      }
    }

    return ret;
  }

  String _trimItem(String item) => trimResults ? item.trim() : item;
}
