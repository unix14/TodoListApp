import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/repo/firebase_repo_interactor.dart'; // Added
import 'package:flutter_example/models/shared_list_config.dart'; // Added
import 'package:firebase_auth/firebase_auth.dart'; // Added
import 'package:flutter_example/common/globals.dart'; // Added (assuming Globals.appBaseUrl)

class ShareListDialog extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ShareListDialog({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<ShareListDialog> createState() => _ShareListDialogState();
}

class _ShareListDialogState extends State<ShareListDialog> {
  late TextEditingController _shortLinkController;
  String _currentShareLink = "";
  bool _isEditingLink = false;
  bool _isLoading = false;
  // Define a base URL for your shareable links. This should come from a config.
  // For now, using a placeholder. Ensure Globals.appBaseUrl is defined.
  String _baseShareUrl = Globals.appBaseUrl ?? "https://yourapp.web.app/list/";


  @override
  void initState() {
    super.initState();
    _shortLinkController = TextEditingController();
    _baseShareUrl = Globals.appBaseUrl ?? _baseShareUrl; // Ensure it's set, fallback if Globals.appBaseUrl is null
    if (_baseShareUrl.endsWith('/')) { // Ensure it has a trailing slash if not already present
        // No, it should not end with / if the shortLinkPath starts with /
        // It should be like https://yourapp.web.app/share (no trailing /)
        // and shortLinkPath is "my-list", so final is https://yourapp.web.app/share/my-list
        // For now, let's assume Globals.appBaseUrl = "https://yourapp.web.app/share" (no trailing slash)
    }

    _fetchExistingShareConfig();
  }

  Future<void> _fetchExistingShareConfig() async {
    setState(() {
      _isLoading = true;
      // Initialize with a default message, possibly context-dependent if called from elsewhere than initState
      _currentShareLink = AppLocale.notSharedYet.getString(context);
    });

    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      setState(() {
        _isLoading = false;
        _currentShareLink = "Error: Not logged in."; // Or handle appropriately
      });
      return;
    }

    try {
      SharedListConfig? config = await FirebaseRepoInteractor.instance.getSharedListConfigById(widget.categoryId);
      if (mounted && config != null && config.adminUserId == currentUserUid) {
        _shortLinkController.text = config.shortLinkPath;
        setState(() {
          _currentShareLink = "${_baseShareUrl.endsWith('/') ? _baseShareUrl : _baseShareUrl + '/'}${config.shortLinkPath}";
          _isEditingLink = false; // Not editing by default when loaded
        });
      } else if (mounted) {
        setState(() {
          // _currentShareLink is already "Not shared yet" from initial setState
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentShareLink = AppLocale.shareError.getString(context);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching share config: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _shortLinkController.dispose();
    super.dispose();
  }

  void _onCopyLink() {
    if (_currentShareLink.isNotEmpty && _currentShareLink != AppLocale.notSharedYet.getString(context) && !_currentShareLink.startsWith("Error:")) {
      Clipboard.setData(ClipboardData(text: _currentShareLink));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.linkCopiedToClipboard.getString(context))),
      );
    }
  }

  Future<void> _onSaveOrUpdateShare() async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: You must be logged in to share.")),
      );
      return;
    }

    final desiredPath = _shortLinkController.text.trim();
    // Basic validation (conceptual) - Firebase function might do more robust checks
    if (desiredPath.isNotEmpty && !RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(desiredPath)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.linkPathInvalid.getString(context))),
        );
        return;
    }
    // If desiredPath is empty, the backend will generate one from categoryName.

    setState(() {
      _isLoading = true;
    });

    try {
      final resultingShortLinkPath = await FirebaseRepoInteractor.instance.createOrUpdateSharedList(
        categoryId: widget.categoryId,
        categoryName: widget.categoryName,
        adminUserId: currentUserUid,
        desiredShortLinkPath: desiredPath,
      );

      if (mounted) {
        setState(() {
          _shortLinkController.text = resultingShortLinkPath;
          _currentShareLink = "${_baseShareUrl.endsWith('/') ? _baseShareUrl : _baseShareUrl + '/'}$resultingShortLinkPath";
          _isEditingLink = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.profilePictureUpdated.getString(context))), // TODO: Change to a more appropriate "Share settings updated" locale
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocale.shareError.getString(context)}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This ensures that if the dialog is rebuilt (e.g. due to orientation change while loading),
    // it still shows a loading indicator or the "Not Shared Yet" message correctly.
    String displayLink = _isLoading ? AppLocale.loading.getString(context) : _currentShareLink;
     if (!_isLoading && displayLink.isEmpty) { // After loading, if still empty, means not shared.
        displayLink = AppLocale.notSharedYet.getString(context);
    }


    return AlertDialog(
      title: Text(AppLocale.shareDialogTitle.getString(context).replaceAll('{categoryName}', widget.categoryName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${AppLocale.shareableLink.getString(context)} $displayLink",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (displayLink != AppLocale.notSharedYet.getString(context) && displayLink != AppLocale.loading.getString(context) && !displayLink.startsWith("Error:"))
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: AppLocale.copyLinkButton.getString(context),
                      onPressed: _onCopyLink,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shortLinkController,
                decoration: InputDecoration(
                  hintText: AppLocale.customLinkPathHint.getString(context),
                  labelText: AppLocale.customLinkPathHint.getString(context),
                  suffixIcon: IconButton(
                      icon: Icon(_shortLinkController.text.isNotEmpty ? Icons.clear : Icons.edit_note), // Changed icon logic
                      tooltip: _shortLinkController.text.isNotEmpty ? AppLocale.clearInput.getString(context) : AppLocale.editSuffixTooltip.getString(context), // TODO: Add these locales
                      onPressed: () {
                          setState(() {
                              if(_shortLinkController.text.isNotEmpty) {
                                  _shortLinkController.clear();
                                  // When cleared, it might imply they want to revert or let system generate
                                  _isEditingLink = true; // Keep in editing mode or let save decide
                              } else {
                                  // If empty and pressed edit, perhaps populate with current if available, or just focus
                              }
                          });
                      },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _isEditingLink = true; // Any change means user is editing the link path
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                AppLocale.authorizedUsersSectionTitle.getString(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text("Authorized users will appear here. (Placeholder)"),
            ]
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocale.cancelButtonText.getString(context)),
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _onSaveOrUpdateShare,
          child: _isLoading
              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
              : Text(
                  // Logic for button text: if a link exists AND user is NOT editing the path field, it's "Update".
                  // Otherwise (no link yet, or user is typing in path field), it's "Save & Share".
                  (_currentShareLink != AppLocale.notSharedYet.getString(context) && !_isEditingLink && _currentShareLink.startsWith("http"))
                      ? AppLocale.updateShareButton.getString(context)
                      : AppLocale.saveShareButton.getString(context)
                ),
        ),
      ],
    );
  }
}
