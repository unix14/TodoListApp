import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/models/shared_list_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/models/user.dart' as AppUser;
import 'package:flutter_example/common/DialogHelper.dart';
// import 'package:flutter_localization/flutter_localization.dart'; // Not directly needed if using AppLocale extension

// Helper extension for nullable firstWhere
extension _FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class ShareListDialog extends StatefulWidget {
  final String categoryId; // For a new share, this is the original category name. For existing, it's the sharedListConfig.id
  final String categoryName; // User-facing display name of the category/list
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
  String _currentShareLinkDisplay = "";
  // bool _isEditingLink = false; // Not strictly needed if button text changes based on _liveConfig
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

    _initializeDialogState();
  }

  void _initializeDialogState() {
    if (_liveConfig != null) {
      _shortLinkController.text = _liveConfig!.shortLinkPath;
      _currentShareLinkDisplay = _getFullShareUrl(_liveConfig!.shortLinkPath);
      if (_liveConfig!.authorizedUserIds.isNotEmpty) {
        _fetchParticipantsDetails(_liveConfig!);
      }
    } else {
      // For a new share, generate a suggested path
      String defaultPath = widget.categoryName.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
      if (defaultPath.isEmpty) defaultPath = "shared-list"; // Fallback for empty/special char names
      _shortLinkController.text = defaultPath;
      // UI will show "Not shared yet" or similar based on _liveConfig being null
      _currentShareLinkDisplay = AppLocale.notSharedYet.getString(context);
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
      if (mounted) _authorizedUserDetails = users;
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
      // If _liveConfig is null, it's a new share. categoryId is originalCategoryName.
      // If _liveConfig exists, categoryId is its ID (already a shared list ID).
      final String idForInteractor = _liveConfig?.id ?? widget.categoryId;

      final resultingConfig = await FirebaseRepoInteractor.instance.createOrUpdateSharedList(
        categoryId: idForInteractor,
        categoryName: widget.categoryName, // Always pass the display name
        adminUserId: currentUserUid,
        desiredShortLinkPath: desiredPath,
        existingConfig: _liveConfig,
      );

      if (mounted) {
        setState(() {
          _liveConfig = resultingConfig;
          _shortLinkController.text = _liveConfig!.shortLinkPath;
          _currentShareLinkDisplay = _getFullShareUrl(_liveConfig!.shortLinkPath);
          // _isEditingLink = false; // Reset editing state
        });
        _fetchParticipantsDetails(_liveConfig!);

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

    bool? confirmed = await DialogHelper.showAlertDialog(
        context: context, // Ensure this context is correct for DialogHelper
        title: AppLocale.removeUserConfirmationTitle.getString(context),
        content: AppLocale.removeUserConfirmationMessage.getString(context).replaceAll('{userName}', userNameToRemove),
        confirmButtonText: AppLocale.okButtonText.getString(context), // Assuming OK for confirm
        cancelButtonText: AppLocale.cancelButtonText.getString(context), // Assuming Cancel for cancel
    );


    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoadingParticipants = true);

      _liveConfig!.authorizedUserIds.remove(userIdToRemove);

      bool success = await FirebaseRepoInteractor.instance.updateSharedListConfig(_liveConfig!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.userRemovedSuccess.getString(context).replaceAll('{userName}', userNameToRemove))),
          );
          // Refresh participants list
          _authorizedUserDetails.removeWhere((user) => user.id == userIdToRemove);
        } else {
          _liveConfig!.authorizedUserIds[userIdToRemove] = true; // Revert optimistic removal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.userRemovedError.getString(context).replaceAll('{userName}', userNameToRemove))),
          );
        }
        setState(() => _isLoadingParticipants = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayLink = _isLoading && _liveConfig == null // Only show top level loading if nothing is loaded yet
        ? AppLocale.loading.getString(context)
        : (_liveConfig?.shortLinkPath == null || _liveConfig!.shortLinkPath.isEmpty
            ? AppLocale.notSharedYet.getString(context)
            : _getFullShareUrl(_liveConfig!.shortLinkPath));

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
                  // onChanged: (value) => setState(() => _isEditingLink = true), // Not strictly needed
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
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                                  ? NetworkImage(user.profilePictureUrl!)
                                  : AssetImage(Globals.defaultProfilePicAsset) as ImageProvider, // Fallback to default asset
                              child: (user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty) && !(user.profilePictureUrl is NetworkImage) // Show icon if no network image and no asset as main BG
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user.name ?? AppLocale.unknownUser.getString(context)),
                            subtitle: isThisUserTheAdmin ? Text(AppLocale.adminText.getString(context)) : null,
                            trailing: (isCurrentUserAdmin && user.id != FirebaseAuth.instance.currentUser?.uid)
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
