import 'package:ini_file/ini_file.dart';

void main() async {
  // create instance and eliminate spaces from results
  // key = abc will return:
  // trimResults = true ?  'abc'
  // trimResults = false ? ' abc'
  IniFile ini = IniFile(trimResults: true);

  await ini.readFile('./example/YSA.ini');

  print(ini.toMap());

  print(ini.getItems('SETTINGS'));
  print(ini.getJsonItems('SETTINGS'));

  ini.setItem('SETTINGS', 'caps', '2');
  print(ini.getItem('SETTINGS', 'caps'));

  ini.setItem('SETTINGS', 'debug', 'false');
  print(ini.getItem('SETTINGS', 'debug'));

  ini.setItems('SETTINGS', [
    ['abc', '1'],
    ['def', '2']
  ]);
  print(ini.getItems('SETTINGS'));

  ini.removeSection('SETTINGS');
  ini.setItem('NEWSECTION', 'newitem', 'new value');
  print(ini.getItems('NEWSECTION'));

  ini = IniFile.emptyFile('./example/new.ini', overrideFile: true);
  ini.setItem('section', 'key', 'value');
  ini.writeFile();
  print(ini.getItem('section', 'key'));
}
