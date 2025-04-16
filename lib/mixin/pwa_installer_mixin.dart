import 'dart:html' as html;

mixin PWAInstallerMixin {
  bool isInstallableRightNow = true;
  html.BeforeInstallPromptEvent? _deferredPrompt;

  /// Register for the 'beforeinstallprompt' event.
  static void registerForInstallPrompt(void Function(html.BeforeInstallPromptEvent) callback) {
    html.window.addEventListener('beforeinstallprompt', (event) {
      final e = event as html.BeforeInstallPromptEvent;
      callback(e);
    });
  }

  /// Check if the app is running in a compatible browser and is not installed as a PWA.
  bool isInstallable() {
    final isChrome = html.window.navigator.userAgent.contains('Chrome');
    final isPwa = html.window.matchMedia('(display-mode: standalone)').matches;
    return isChrome && !isPwa && isInstallableRightNow;
  }

  /// Handle the install prompt registration.
  void initializeInstallPrompt() {
    if (isInstallable()) {
      registerForInstallPrompt((event) {
        _deferredPrompt = event;
      });
    } else {
      isInstallableRightNow = false;
    }
  }

  /// Show the install prompt if available.
  void showInstallPrompt() {
    print('showInstallPrompt: _deferredPrompt = ${_deferredPrompt}');

    if (_deferredPrompt != null) {
      _deferredPrompt?.prompt();
      _deferredPrompt?.userChoice.then((result) {
        print('User response: ${result}');
        // You can handle user response here if needed, like logging or tracking installs.
        _deferredPrompt = null; // Reset after showing the prompt
        isInstallableRightNow = false;
      });
    } else {
      isInstallableRightNow = false;
    }
  }
}