import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/test_setup.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Compare Command Tests', () {
    late TestSetup testSetup;

    setUp(() async {
      testSetup = TestSetup();
      await testSetup.setUp();
    });

    tearDown(() async {
      await testSetup.tearDown();
    });

    test('compare command works as expected', () async {
      // 1. Copy app_v100 to tempDir
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      // 2. Generate API documentation for v100 and store outside git repo
      final apiFilesDir = Directory(p.join(testSetup.tempDir.parent.path, 'api_files'));
      await apiFilesDir.create(recursive: true);
      final v100ApiFile = p.join(apiFilesDir.path, 'api_v100.json');
      await testSetup.runApiGuard('generate', ['--out', v100ApiFile]);

      // 3. Copy app_v101 over tempDir (this has changes: added _internalId to Product, removed _PrivateClass)
      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);
      await testSetup.commitChanges('feat: API changes for v${TestConstants.patchVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.patchVersion}'], workingDir: testSetup.tempDir.path);

      // 4. Generate API documentation for v101 and store outside git repo
      final v101ApiFile = p.join(apiFilesDir.path, 'api_v101.json');
      await testSetup.runApiGuard('generate', ['--out', v101ApiFile]);

      // 5. Run compare command between the two API files directly
      final compareOutputFile = p.join(testSetup.tempDir.path, 'compare_output.txt');
      await testSetup.runApiGuard('compare', [
        '--base-ref',
        v100ApiFile,
        '--new-ref',
        v101ApiFile,
        '--out',
        compareOutputFile,
      ]);

      // 6. Read the compare output
      final compareOutput = await File(compareOutputFile).readAsString();

      // 7. Compare to expected snapshot
      final expectedCompareFile = File(p.join(testSetup.fixtures.fixturesDir.path, 'expected_compare_v100_v101.txt'));

      if (!expectedCompareFile.existsSync()) {
        expectedCompareFile.createSync();
        expectedCompareFile.writeAsStringSync(compareOutput);
        print('Created expected snapshot file: ${expectedCompareFile.path}');
      }

      final expectedCompareContent = await expectedCompareFile.readAsString();
      expect(compareOutput, equalsIgnoringWhitespace(expectedCompareContent));
    });
  }, timeout: const Timeout(Duration(minutes: 3)));
}
