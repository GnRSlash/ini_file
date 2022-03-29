import 'package:ini_file/ini_file.dart';

void main() async {
  IniFile ini = IniFile();

  await ini.readFile('./example/YSA.ini');

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
}
