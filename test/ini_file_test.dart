import 'dart:io';

import 'package:ini_file/ini_file.dart';
import 'package:test/test.dart';

void main() async {
  IniFile ini = IniFile();
  ini.trimResults = true;
  await ini.readFile('./example/YSA.ini');

  group('IniFile tests...', () {
    setUp(() async {});

    test('get all section items', () {
      expect(ini.getItems('settings'), <List<String>>[
        ['caps', '1'],
        ['ignore', 'true']
      ]);
    });

    test('get section in json', () {
      expect(ini.getJsonItems('tcp'), {
        'tcp': {'port': '8080', 'ip': 'localhost'}
      });
    });

    test('get one section item', () {
      expect(ini.getItem('Crazysection', 'everywhere'), '5');
    });

    test('set existing key', () {
      expect(() => ini.setItem('tcp', 'port', '8090'), returnsNormally);
      expect(ini.getItem('tcp', 'port'), '8090');
    });

    test('set new key', () {
      expect(() => ini.setItem('tcp', 'port_backup', '8100'), returnsNormally);
      expect(ini.getItem('tcp', 'port_backup'), '8100');
    });

    test('writing a changed copy of the file', () async {
      File file = File('./example/copy.ini');
      if (await file.exists()) {
        file.delete();
      }

      expect(() => ini.writeFile('./example/copy.ini'), returnsNormally);
      expect(await file.exists(), true);
    });

    test('remove entire section', () async {
      expect(() => ini.removeSection('tcp'), returnsNormally);
      File file = File('./example/removed.ini');
      if (await file.exists()) {
        file.delete();
      }

      expect(() => ini.writeFile('./example/removed.ini'), returnsNormally);
      expect(await file.exists(), true);
    });
  });
}
