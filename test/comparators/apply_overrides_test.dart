import 'package:mtrust_api_guard/config/config.dart';
import 'package:mtrust_api_guard/config/magnitude_override.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/apply_overrides.dart';
import 'package:mtrust_api_guard/models/doc_items.dart';
import 'package:mtrust_api_guard/models/doc_type.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DocComponent _component({
  String name = 'MyClass',
  String? filePath,
  List<String> superClasses = const [],
  List<String> superClassPackages = const [],
  List<String> interfaces = const [],
  List<String> mixins = const [],
  List<String> annotations = const [],
}) {
  return DocComponent(
    name: name,
    description: '',
    constructors: const [],
    properties: const [],
    methods: const [],
    filePath: filePath,
    superClasses: superClasses,
    superClassPackages: superClassPackages,
    interfaces: interfaces,
    mixins: mixins,
    annotations: annotations,
  );
}

ComponentApiChange _componentChange(
  DocComponent component, {
  ApiChangeOperation operation = ApiChangeOperation.addition,
}) {
  return ComponentApiChange(component: component, operation: operation);
}

PropertyApiChange _propertyChange(DocComponent component) {
  return PropertyApiChange(
    component: component,
    operation: ApiChangeOperation.addition,
    property: const DocProperty(
      name: 'myProp',
      type: DocType(name: 'String'),
      description: '',
      features: [],
    ),
  );
}

ApiGuardConfig _config(List<MagnitudeOverride> overrides) {
  return ApiGuardConfig(
    include: {'lib/**.dart'},
    exclude: {},
    generateBadge: false,
    magnitudeOverrides: overrides,
  );
}

MagnitudeOverride _fromPackageOverride(
  List<String> packages, {
  String magnitude = 'ignore',
}) {
  return MagnitudeOverride(
    operations: ['*'],
    magnitude: magnitude,
    selection: OverrideSelection(fromPackage: packages),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('applyMagnitudeOverrides — from_package selection', () {
    group('component defined in the target package (package: URI filePath)', () {
      test('ignores a class defined directly in the matched package', () {
        final component = _component(
          name: 'AndroidSelector',
          filePath: 'package:patrol/src/platform/contracts/contracts.dart',
        );
        final change = _componentChange(component, operation: ApiChangeOperation.removal);
        final config = _config([
          _fromPackageOverride(['patrol'])
        ]);

        applyMagnitudeOverrides([change], config);

        expect(change.getMagnitude(), ApiChangeMagnitude.ignore);
      });

      test('matches when filePath has multiple path segments in the package', () {
        final component = _component(
          filePath: 'package:some_pkg/src/deep/nested/file.dart',
        );
        final change = _componentChange(component);
        final config = _config([
          _fromPackageOverride(['some_pkg'])
        ]);

        applyMagnitudeOverrides([change], config);

        expect(change.getMagnitude(), ApiChangeMagnitude.ignore);
      });

      test('does NOT match a different package name', () {
        final component = _component(
          filePath: 'package:patrol/src/platform/contracts/contracts.dart',
        );
        final change = _componentChange(component, operation: ApiChangeOperation.removal);
        final config = _config([
          _fromPackageOverride(['other_package'])
        ]);

        applyMagnitudeOverrides([change], config);

        // removal defaults to major — should be unchanged
        expect(change.getMagnitude(), ApiChangeMagnitude.major);
      });

      test('does NOT match a component with a relative (project-owned) filePath', () {
        final component = _component(
          filePath: 'lib/src/my_class.dart',
        );
        final change = _componentChange(component, operation: ApiChangeOperation.removal);
        final config = _config([
          _fromPackageOverride(['patrol'])
        ]);

        applyMagnitudeOverrides([change], config);

        expect(change.getMagnitude(), ApiChangeMagnitude.major);
      });

      test('does NOT match a component with no filePath', () {
        final component = _component(filePath: null);
        final change = _componentChange(component, operation: ApiChangeOperation.removal);
        final config = _config([
          _fromPackageOverride(['patrol'])
        ]);

        applyMagnitudeOverrides([change], config);

        expect(change.getMagnitude(), ApiChangeMagnitude.major);
      });

      test('matches any of multiple packages listed', () {
        final component = _component(
          filePath: 'package:patrol_finders/src/finder.dart',
        );
        final change = _componentChange(component, operation: ApiChangeOperation.removal);
        final config = _config([
          _fromPackageOverride(['patrol', 'patrol_finders'])
        ]);

        applyMagnitudeOverrides([change], config);

        expect(change.getMagnitude(), ApiChangeMagnitude.ignore);
      });

      test('can downgrade (not just ignore) a change from an external package', () {
        final component = _component(
          filePath: 'package:patrol/src/platform/contracts/contracts.dart',
        );
        final change = _componentChange(component, operation: ApiChangeOperation.removal);
        final config = _config([
          _fromPackageOverride(['patrol'], magnitude: 'patch')
        ]);

        applyMagnitudeOverrides([change], config);

        expect(change.getMagnitude(), ApiChangeMagnitude.patch);
      });

      test('applies to property changes whose enclosing component is in the package', () {
        // PropertyApiChange uses the component's filePath via the enclosing context.
        // The from_package check applies to the enclosing component.
        final component = _component(
          name: 'AndroidSelector',
          filePath: 'package:patrol/src/platform/contracts/contracts.dart',
        );
        final change = _propertyChange(component);

        // Override matches the enclosing component's package
        final override = MagnitudeOverride(
          operations: ['*'],
          magnitude: 'ignore',
          selection: OverrideSelection(
            enclosing: OverrideSelection(fromPackage: ['patrol']),
          ),
        );
        final config = _config([override]);

        applyMagnitudeOverrides([change], config);

        expect(change.getMagnitude(), ApiChangeMagnitude.ignore);
      });
    });

    group('component whose superclass comes from the target package (existing behaviour)', () {
      test('still matches when superClassPackages contains the package', () {
        final component = _component(
          filePath: 'lib/src/my_widget.dart',
          superClasses: ['Widget'],
          superClassPackages: ['flutter'],
        );
        final change = _componentChange(component, operation: ApiChangeOperation.removal);
        final config = _config([
          _fromPackageOverride(['flutter'])
        ]);

        applyMagnitudeOverrides([change], config);

        expect(change.getMagnitude(), ApiChangeMagnitude.ignore);
      });
    });

    group('no from_package selection (regression guard)', () {
      test('override without selection still applies universally', () {
        final component = _component(filePath: 'lib/src/foo.dart');
        final change = _componentChange(component, operation: ApiChangeOperation.removal);
        final override = MagnitudeOverride(operations: ['*'], magnitude: 'patch');
        final config = _config([override]);

        applyMagnitudeOverrides([change], config);

        expect(change.getMagnitude(), ApiChangeMagnitude.patch);
      });

      test('first matching override wins, subsequent overrides are skipped', () {
        final component = _component(
          filePath: 'package:patrol/src/contracts.dart',
        );
        final change = _componentChange(component, operation: ApiChangeOperation.removal);
        final config = _config([
          _fromPackageOverride(['patrol'], magnitude: 'patch'),
          _fromPackageOverride(['patrol'], magnitude: 'ignore'),
        ]);

        applyMagnitudeOverrides([change], config);

        expect(change.getMagnitude(), ApiChangeMagnitude.patch);
      });
    });
  });
}
