// Stub for PWAInstallerMixin for non-web platforms

mixin PWAInstallerMixin {
  bool isInstallableRightNow = false; // Default to not installable

  // ignore: unused_element
  dynamic _deferredPrompt; // Keep type dynamic or Object? to avoid html types

  bool isInstallable() {
    return false; // Never installable on non-web
  }

  void initializeInstallPrompt() {
    // No-op
    print('PWAInstallerMixinStub: initializeInstallPrompt called');
    isInstallableRightNow = false;
  }

  void showInstallPrompt() {
    // No-op
    print('PWAInstallerMixinStub: showInstallPrompt called');
    isInstallableRightNow = false;
  }

  // Add any other methods/properties from the real mixin with stub implementations
}
