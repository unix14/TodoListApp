// Conditional export for PWAInstallerMixin
// This allows using one import path in other files, and Dart handles
// choosing the correct implementation based on the platform.

export 'pwa_installer_mixin_stub.dart' // Default (VM, mobile, desktop)
    if (dart.library.html) 'pwa_installer_mixin_real.dart'; // Web implementation
