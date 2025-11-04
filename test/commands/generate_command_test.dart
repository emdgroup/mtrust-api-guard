import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/test_setup.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Generate Command Tests', () {
    late TestSetup testSetup;

    setUp(() async {
      testSetup = TestSetup();
      await testSetup.setUp();
    });

    tearDown(() async {
      await testSetup.tearDown();
    });

    test('generate command works as expected', () async {
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      final generatedFilePath = p.join(testSetup.tempDir.path, 'generate_out', 'generated_api_v100.json');
      File(generatedFilePath).createSync(recursive: true);
      await testSetup.runApiGuard('generate', ["--out", generatedFilePath]);

      final expectedGeneratedFilePath = p.join(testSetup.fixtures.fixturesDir.path, 'apiV100.json');

      if (!File(expectedGeneratedFilePath).existsSync()) {
        File(expectedGeneratedFilePath).createSync();
        File(expectedGeneratedFilePath).writeAsStringSync(
          await File(generatedFilePath).readAsString(),
        );
      }

      final expectedGeneratedContent = await File(expectedGeneratedFilePath).readAsString();
      final generatedContent = await File(generatedFilePath).readAsString();
      expect(generatedContent, equalsIgnoringWhitespace(expectedGeneratedContent));
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
