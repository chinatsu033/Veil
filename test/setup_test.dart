import 'package:test/test.dart';

import '../setup.dart' as setup;

void main() {
  group('setup.dart', () {
    test('parses -v as verbose mode', () {
      final results = setup.createSetupArgParser().parse(['android', '-v']);

      expect(results['verbose'], isTrue);
      expect(results.rest, ['android']);
    });

    test('accepts dev application environment', () {
      final results = setup.createSetupArgParser().parse([
        'android',
        '--env',
        'dev',
      ]);

      expect(results['env'], 'dev');
    });

    test('Flutter build environment does not depend on Core SHA256', () {
      expect(setup.createBuildEnvironment('dev'), {'APP_ENV': 'dev'});
    });

    test('omits verbose from flutter build args by default', () {
      final args = setup.createFlutterBuildArgs(
        platform: 'android',
        verbose: false,
      );

      expect(args, ['dart-define-from-file=env.json', 'split-per-abi']);
    });

    test('adds verbose to flutter build args with -v', () {
      final args = setup.createFlutterBuildArgs(
        platform: 'android',
        verbose: true,
      );

      expect(args, [
        'verbose',
        'dart-define-from-file=env.json',
        'split-per-abi',
      ]);
    });

    test('refuses to package while a native build hook is skipped', () {
      const pubspec = '''
hooks:
  user_defines:
    setup:
      build_assets: false
    rust_api:
      build_assets: true
''';

      expect(setup.packagesNotBuildingAssets(pubspec), ['setup']);
      expect(setup.packagesNotBuildingAssets('name: x\n'), isEmpty);
    });

    test('packages every Linux format on every architecture', () {
      expect(setup.createPackageTargets('linux', null), 'deb,appimage,rpm');
      expect(setup.createPackageTargets('linux', 'deb'), 'deb');
      expect(setup.createPackageTargets('macos', null), 'dmg');
    });

    test('downloads the appimagetool build matching the host', () {
      expect(setup.appImageToolArch('arm64'), 'aarch64');
      expect(setup.appImageToolArch('amd64'), 'x86_64');
    });

    test('labels Intel/AMD artifacts x86 and keeps arm64', () {
      expect(setup.artifactArch('amd64'), 'x86');
      expect(setup.artifactArch('arm64'), 'arm64');
    });

    test('renames x86_64/amd64 artifact names to x86', () {
      expect(
        setup.normalizeArtifactName('Veil-0.2.2-android-x86_64.apk'),
        'Veil-0.2.2-android-x86.apk',
      );
      expect(
        setup.normalizeArtifactName('Veil-0.2.2-windows-amd64-setup.exe'),
        'Veil-0.2.2-windows-x86-setup.exe',
      );
      expect(
        setup.normalizeArtifactName('Veil-0.2.2-android-arm64-v8a.apk'),
        'Veil-0.2.2-android-arm64-v8a.apk',
      );
    });

    test('appimagetool wrapper pins the host architecture', () {
      final script = setup.appImageToolWrapper('/opt/tool', 'aarch64');

      expect(script, contains('ARCH=arm_aarch64 '));
      expect(
        setup.appImageToolWrapper('/opt/tool', 'x86_64'),
        contains('ARCH=x86_64 '),
      );
      expect(script, contains('APPIMAGE_EXTRACT_AND_RUN=1'));
      expect(script, contains('exec "/opt/tool" "\$@"'));
    });
  });
}
