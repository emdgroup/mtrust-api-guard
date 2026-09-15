/// The names and shapes a dead code scan has to leave alone, because no
/// reference in source settles them.
library;

/// Filename suffixes emitted by the common Dart code generators. Files with
/// these names are analyzed, so that a declaration used only from generated
/// code is not misreported, but their own declarations are never reported.
const generatedSuffixes = [
  '.g.dart',
  '.freezed.dart',
  '.mocks.dart',
  '.gr.dart',
  '.config.dart',
  '.gen.dart',
  '.pb.dart',
  '.pbenum.dart',
  '.pbjson.dart',
  '.pbserver.dart',
];

/// Banner that `build_runner` and friends put at the top of generated files.
const generatedBanner = 'GENERATED CODE - DO NOT MODIFY BY HAND';

/// Members the language or the core libraries call without a source-level
/// reference, so an unreferenced declaration with one of these names is not
/// evidence of anything.
const implicitlyInvokedNames = {'==', 'hashCode', 'toString', 'noSuchMethod', 'call', 'toJson', 'fromJson'};

/// Whether [file], whose text is [content], was written by a code generator
/// rather than by hand.
///
/// Generated files are still analyzed, so a declaration used only from
/// generated code is not misreported, but nothing inside one is ever reported:
/// deleting it would only make the generator write it again.
bool isGeneratedFile(String file, String content) {
  if (generatedSuffixes.any(file.endsWith)) return true;
  // A banner counts only where a generator would have written it.
  final head = content.length > 2048 ? content.substring(0, 2048) : content;
  return head.contains(generatedBanner);
}
