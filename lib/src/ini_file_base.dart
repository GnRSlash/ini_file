import 'dart:convert';
import 'dart:io';

/// class to work with ini files and keep all comments and formats
class IniFile {
  late File _file;
  Encoding _encoding = utf8;
  List<String> _lines = [];

  /// keep tracking of sections to improve search
  final List<String> _sections = [];
  final RegExp _sectionPattern = RegExp(r'^[^#;\s]+[\[\]]', multiLine: true);
  final RegExp _entryPattern = RegExp(r'^([^#;\s]+)([\s]*)=(.*?)$', multiLine: true);

  IniFile();

  factory IniFile.emptyFile(String filePath) {
    IniFile newini = IniFile();
    newini._file = File(filePath);
    if (!newini._file.existsSync()) {
      newini._file.create();
    }
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

  /// get section items and convert to json format
  Map<String, Map<String, String>> getJsonItems(String section) {
    Map<String, Map<String, String>> ret = {section: {}};
    List<List<String>> items = getItems(section);
    for (List<String> item in items) {
      ret[section]?.addAll({item[0]: item[1]});
    }
    return ret;
  }

  /// get section items and returns in list of list items
  List<List<String>> getItems(String section) {
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
        ret.add([items[0].trim(), items[1].trim()]);
      }
    }
    return ret;
  }

  /// get just one key from section
  String? getItem(String section, String key) {
    List<List<String>> items = getItems(section);
    for (List<String> item in items) {
      if (item[0].toLowerCase() == key) {
        return item[1];
      }
    }
    return null;
  }

  /// change existing key in section or create new key and new section if they don't exist
  /// throws exceptions
  void setItem(String section, String key, String value) {
    if (key.contains(' ') || section.contains(' ')) {
      throw ('Sections and Keys must not contain spaces!');
    }
    int firstSectionLine = _getOrCreateSection(section);
    int line = firstSectionLine;
    while (line < _lines.length) {
      if (_entryPattern.hasMatch(_lines[line])) {
        List<String> items = _lines[line].split('=');
        if (items[0].trim().toLowerCase() == key.toLowerCase()) {
          // key found, change it
          _lines[line] = '$key = $value';
          return;
        }
      }
      if (_sectionPattern.hasMatch(_lines[line])) {
        // section does not contains this key
        break;
      }
      line++;
    }
    // key not found, create it at the begining of the section
    _lines.insert(firstSectionLine, '$key = $value');
  }

  void setItems(String section, List<List<String>> values) {
    for (List<String> element in values) {
      setItem(section, element[0], element[1]);
    }
  }

  /// delete entire section if it exists
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

  @override
  String toString() {
    return _lines.join('\r\n');
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
      if (_lines[_lines.length - 1].trim().isNotEmpty) {
        _lines.add('');
      }
      _lines.add('[$section]');
      return _lines.length;
    }
    return _getSection(section);
  }

  /// return next line number of the section
  int _getSection(String section) {
    section = section.toLowerCase();
    for (int i = 0; i < _lines.length; i++) {
      if ((_sectionPattern.stringMatch(_lines[i]) ?? '').toLowerCase() == '[$section]') {
        return i + 1;
      }
    }
    throw Exception("can't create section, internal error!");
  }
}
