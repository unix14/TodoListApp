import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/models/shared_list_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/models/user.dart' as AppUser;
import 'package:flutter_example/common/DialogHelper.dart';
import 'package:flutter_localization/flutter_localization.dart'; // Keep for FlutterLocalization.instance if used, or for getString extension.

// Helper extension for nullable firstWhere, if not available globally
extension _FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class ShareListDialog extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final SharedListConfig? existingConfig;

  const ShareListDialog({
    Key? key,
    required this.categoryId,
    required this.categoryName,
    this.existingConfig,
  }) : super(key: key);

  @override
  State<ShareListDialog> createState() => _ShareListDialogState();
}

class _ShareListDialogState extends State<ShareListDialog> {
  late TextEditingController _shortLinkController;
  String _currentShareLinkDisplay = ""; // Will be localized in build or didChangeDependencies
  bool _isLoading = false;
  bool _isLoadingParticipants = false;
  List<AppUser.User> _authorizedUserDetails = [];
  SharedListConfig? _liveConfig;

  final String _baseShareUrlSegment = "/list/";

  @override
  void initState() {
    super.initState();
    _shortLinkController = TextEditingController();
    _liveConfig = widget.existingConfig;
    _initializeDialogStateNonLocalized();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Localize initial display string now that context is available
    if (_liveConfig == null && _currentShareLinkDisplay == "Not shared yet. Create a link to share.") { // Check against non-localized placeholder
        setState(() {
             _currentShareLinkDisplay = AppLocale.notSharedYet.getString(context);
        });
    } else if (_liveConfig != null && _currentShareLinkDisplay.isEmpty) {
        // This might happen if initState's _getFullShareUrl was called before context was ready for AppLocale.loading
        // Or if it was just not set.
        _currentShareLinkDisplay = _getFullShareUrl(_liveConfig!.shortLinkPath);
    }
  }

  void _initializeDialogStateNonLocalized() {
    if (_liveConfig != null) {
      _shortLinkController.text = _liveConfig!.shortLinkPath;
      _currentShareLinkDisplay = _getFullShareUrl(_liveConfig!.shortLinkPath); // This is URL, not localized
      if (_liveConfig!.authorizedUserIds.isNotEmpty) {
        _fetchParticipantsDetails(_liveConfig!);
      }
    } else {
      String defaultPath = widget.categoryName.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
      if (defaultPath.isEmpty) defaultPath = "shared-list";
      _shortLinkController.text = defaultPath;
      // Use a non-localized placeholder, will be updated in didChangeDependencies
      _currentShareLinkDisplay = "Not shared yet. Create a link to share.";
    }
  }

  String _getFullShareUrl(String shortPath) {
    return "${Globals.appBaseUrl}$_baseShareUrlSegment$shortPath";
  }

  Future<void> _fetchParticipantsDetails(SharedListConfig config) async {
    if (config.authorizedUserIds.isEmpty || !mounted) return;

    setState(() => _isLoadingParticipants = true);
    try {
      final users = await FirebaseRepoInteractor.instance.getUsersDetails(config.authorizedUserIds.keys.toList());
      if (mounted) {
        setState(() => _authorizedUserDetails = users);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.fetchParticipantsError.getString(context).replaceAll('{errorDetails}', e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isLoadingParticipants = false);
    }
  }

  @override
  void dispose() {
    _shortLinkController.dispose();
    super.dispose();
  }

  void _onCopyLink() {
    if (_liveConfig?.shortLinkPath != null && _liveConfig!.shortLinkPath.isNotEmpty) {
       final fullLink = _getFullShareUrl(_liveConfig!.shortLinkPath);
      Clipboard.setData(ClipboardData(text: fullLink));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.linkCopiedToClipboard.getString(context))),
      );
    }
  }

  Future<void> _onSaveOrUpdateShare() async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.loginToSharePrompt.getString(context))),
      );
      return;
    }

    final desiredPath = _shortLinkController.text.trim();
    if (desiredPath.isEmpty || !RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(desiredPath)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.linkPathInvalid.getString(context))),
        );
        return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final String idForInteractor = _liveConfig?.id ?? widget.categoryId;

      final resultingConfig = await FirebaseRepoInteractor.instance.createOrUpdateSharedList(
        categoryIdOrName: idForInteractor, // Changed from categoryId
        listDisplayName: widget.categoryName, // Changed from categoryName
        adminUserId: currentUserUid,
        desiredShortLinkPath: desiredPath,
        existingConfig: _liveConfig,
      );

      if (mounted) {
        setState(() {
          _liveConfig = resultingConfig;
          _shortLinkController.text = _liveConfig!.shortLinkPath;
          _currentShareLinkDisplay = _getFullShareUrl(_liveConfig!.shortLinkPath);
        });
        if (_liveConfig != null) _fetchParticipantsDetails(_liveConfig!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.shareSettingsUpdated.getString(context))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocale.shareError.getString(context)}: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeUserFromSharedList(String userIdToRemove) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (_liveConfig == null || _liveConfig!.adminUserId != currentUserUid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.adminRequiredToRemoveUser.getString(context))));
      return;
    }

    final AppUser.User? userToRemoveDetails = _authorizedUserDetails.firstWhereOrNull((u) => u.id == userIdToRemove);
    final String userNameToRemove = userToRemoveDetails?.name ?? AppLocale.unknownUser.getString(context);

    // Using DialogHelper with VoidCallbacks
    DialogHelper.showAlertDialog(
        context: context,
        title: AppLocale.removeUserConfirmationTitle.getString(context),
        text: AppLocale.removeUserConfirmationMessage.getString(context).replaceAll('{userName}', userNameToRemove),
        onOkButton: () async { // OK action
            Navigator.of(context, rootNavigator: true).pop(); // Close the confirmation dialog first
            if (!mounted) return;
            setState(() => _isLoadingParticipants = true);

            _liveConfig!.authorizedUserIds.remove(userIdToRemove);

            bool success = await FirebaseRepoInteractor.instance.updateSharedListConfig(_liveConfig!);
            if (mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocale.userRemovedSuccess.getString(context).replaceAll('{userName}', userNameToRemove))),
                );
                setState(() { // Update UI immediately
                  _authorizedUserDetails.removeWhere((user) => user.id == userIdToRemove);
                });
              } else {
                _liveConfig!.authorizedUserIds[userIdToRemove] = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocale.userRemovedError.getString(context).replaceAll('{userName}', userNameToRemove))),
                );
              }
              setState(() => _isLoadingParticipants = false);
            }
        },
        onCancelButton: () { // Cancel action
            Navigator.of(context, rootNavigator: true).pop();
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayLink = (_isLoading && _liveConfig == null)
        ? AppLocale.loading.getString(context)
        : (_currentShareLinkDisplay.isEmpty || _currentShareLinkDisplay == "Loading link state..."
            ? AppLocale.notSharedYet.getString(context) // Ensure localization if it was a placeholder
            : _currentShareLinkDisplay);

    bool isCurrentUserAdmin = _liveConfig?.adminUserId == FirebaseAuth.instance.currentUser?.uid || _liveConfig == null;

    return AlertDialog(
      title: Text(AppLocale.shareDialogTitle.getString(context).replaceAll('{categoryName}', widget.categoryName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_isLoading && _liveConfig == null)
              Padding(padding: const EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${AppLocale.shareableLink.getString(context)} $displayLink",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (displayLink != AppLocale.notSharedYet.getString(context) && displayLink != AppLocale.loading.getString(context))
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: AppLocale.copyLinkButton.getString(context),
                      onPressed: _onCopyLink,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (isCurrentUserAdmin)
                TextFormField(
                  controller: _shortLinkController,
                  decoration: InputDecoration(
                    labelText: AppLocale.customLinkPathHint.getString(context),
                    suffixIcon: IconButton(
                        icon: Icon(_shortLinkController.text.isNotEmpty ? Icons.clear : Icons.edit_note),
                        tooltip: _shortLinkController.text.isNotEmpty ? AppLocale.clearInput.getString(context) : AppLocale.editSuffixTooltip.getString(context),
                        onPressed: () => setState(() => _shortLinkController.clear()),
                    ),
                  ),
                )
              else if (_liveConfig != null)
                  Text("${AppLocale.customLinkPathHint.getString(context)}: ${_liveConfig!.shortLinkPath}"),

              const SizedBox(height: 16),
              Text( AppLocale.authorizedUsersSectionTitle.getString(context), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _isLoadingParticipants
                ? Center(child: CircularProgressIndicator())
                : (_liveConfig == null || _authorizedUserDetails.isEmpty
                    ? Text(AppLocale.noAuthorizedUsers.getString(context))
                    : Column(
                        children: _authorizedUserDetails.map((user) {
                          bool isThisUserTheAdmin = user.id == _liveConfig?.adminUserId;
                          final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                                  ? NetworkImage(user.profilePictureUrl!)
                                  : AssetImage(Globals.defaultProfilePicAsset) as ImageProvider,
                              child: (user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty)
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user.name ?? AppLocale.unknownUser.getString(context)),
                            subtitle: isThisUserTheAdmin ? Text(AppLocale.adminText.getString(context)) : null,
                            trailing: (isCurrentUserAdmin && user.id != null && user.id != currentUserId)
                                ? IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error),
                                    tooltip: AppLocale.removeUserButtonTooltip.getString(context),
                                    onPressed: () => _removeUserFromSharedList(user.id!),
                                  )
                                : null,
                          );
                        }).toList(),
                      )),
            ]
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocale.cancelButtonText.getString(context)),
          onPressed: _isLoading || _isLoadingParticipants ? null : () => Navigator.of(context).pop(),
        ),
        if (isCurrentUserAdmin)
          ElevatedButton(
            onPressed: _isLoading || _isLoadingParticipants ? null : _onSaveOrUpdateShare,
            child: (_isLoading && !_isLoadingParticipants)
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
                : Text(
                   _liveConfig != null
                      ? AppLocale.updateShareButton.getString(context)
                      : AppLocale.saveShareButton.getString(context)
                  ),
          ),
      ],
    );
  }
}
