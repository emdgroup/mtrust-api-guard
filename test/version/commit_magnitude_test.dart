import 'package:collection/collection.dart';
import 'package:conventional/conventional.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/version/commit_magnitude.dart';
import 'package:test/test.dart';

/// Commits in the shape `git log` prints them, which is what the parser reads.
List<Commit> commits(List<String> subjects) => Commit.parseCommits(
  subjects
      .mapIndexed(
        (index, subject) =>
            'commit ${'$index'.padLeft(40, '0')}\n'
            'Author: Test User <test@example.com>\n'
            'Date:   Fri May 21 17:26:46 2021 +0800\n'
            '\n'
            '    $subject\n',
      )
      .join('\n'),
);

void main() {
  group('magnitudeFromCommits', () {
    test('asks for nothing when no type says anything about a release', () {
      expect(
        magnitudeFromCommits(commits(['chore: bump the lockfile', 'docs: fix a typo'])),
        ApiChangeMagnitude.ignore,
      );
    });

    test('reads a feat as a minor', () {
      expect(magnitudeFromCommits(commits(['feat: add the dead-code command'])), ApiChangeMagnitude.minor);
    });

    test('reads a fix and a perf as a patch', () {
      expect(magnitudeFromCommits(commits(['fix: stop crashing'])), ApiChangeMagnitude.patch);
      expect(magnitudeFromCommits(commits(['perf: scan once'])), ApiChangeMagnitude.patch);
    });

    test('reads a bang as a major, whatever the type', () {
      expect(magnitudeFromCommits(commits(['refactor!: drop the old flag'])), ApiChangeMagnitude.major);
    });

    test('takes the highest of them', () {
      expect(
        magnitudeFromCommits(commits(['fix: stop crashing', 'feat: add a command', 'chore: tidy up'])),
        ApiChangeMagnitude.minor,
      );
    });

    test('ignores a type it does not know', () {
      expect(magnitudeFromCommits(commits(['wip: something'])), ApiChangeMagnitude.ignore);
    });

    test('says nothing for no commits at all', () {
      expect(magnitudeFromCommits(const []), ApiChangeMagnitude.ignore);
    });
  });
}
