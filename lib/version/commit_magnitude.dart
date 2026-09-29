import 'package:conventional/conventional.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';

/// The bump the conventional commit types in [commits] ask for.
///
/// The API diff cannot see a change that the exported API does not show, so a
/// release that only adds a command, or only touches code behind the exports,
/// comes out as a patch. Read as a floor next to the diff, these types say what
/// the change was meant to be. Any other type says nothing about the size of a
/// release and leaves the floor at [ApiChangeMagnitude.ignore].
ApiChangeMagnitude magnitudeFromCommits(Iterable<Commit> commits) {
  var magnitude = ApiChangeMagnitude.ignore;
  for (final commit in commits) {
    magnitude = magnitude.atLeast(switch ((commit.breaking, commit.type.toLowerCase())) {
      (true, _) => ApiChangeMagnitude.major,
      (_, 'feat') => ApiChangeMagnitude.minor,
      (_, 'fix' || 'perf') => ApiChangeMagnitude.patch,
      _ => ApiChangeMagnitude.ignore,
    });
  }
  return magnitude;
}
