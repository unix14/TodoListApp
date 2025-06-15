import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_localization/flutter_localization.dart'; // Added import
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/models/shared_list_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/models/user.dart' as AppUser; // Added for User model
import 'package:flutter_example/common/DialogHelper.dart'; // Added for confirmation dialog

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
  bool _isLoadingParticipants = false; // New state for loading participants
  List<AppUser.User> _authorizedUserDetails = []; // New state for participant details
  SharedListConfig? _existingConfig; // To store the fetched config for reuse

  // Define a base URL for your shareable links.
  // Globals.appBaseUrl should be like "https://todo-later.web.app"
  // We will append "/list/" to it.
  String _baseShareUrlSegment = "/list/"; // Specific path segment for shared lists

  @override
  void initState() {
    super.initState();
    _shortLinkController = TextEditingController();
    // _baseShareUrl is effectively Globals.appBaseUrl
    _fetchExistingShareConfig();
  }

  String _getFullShareUrl(String shortPath) {
    final baseUrl = Globals.appBaseUrl ?? "https://todo-later.web.app"; // Fallback if Globals.appBaseUrl is null
    return "$baseUrl$_baseShareUrlSegment$shortPath";
  }

  Future<void> _fetchExistingShareConfig() async {
    setState(() {
      _isLoading = true;
      _currentShareLink = FlutterLocalization.instance.getString(context, AppLocale.loading);
    });

    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      setState(() {
        _isLoading = false;
        _currentShareLink = FlutterLocalization.instance.getString(context, AppLocale.loginToSharePrompt);
      });
      return;
    }

    try {
      _existingConfig = await FirebaseRepoInteractor.instance.getSharedListConfigById(widget.categoryId);
      if (mounted && _existingConfig != null) {
        if (_existingConfig!.adminUserId == currentUserUid) {
            _shortLinkController.text = _existingConfig!.shortLinkPath;
        }
        setState(() {
          _currentShareLink = _getFullShareUrl(_existingConfig!.shortLinkPath);
          _isEditingLink = false;
        });
        _fetchParticipantsDetails(_existingConfig!);
      } else if (mounted) {
        setState(() {
           _currentShareLink = FlutterLocalization.instance.getString(context, AppLocale.notSharedYet);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _currentShareLink = FlutterLocalization.instance.getString(context, AppLocale.shareError); });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(FlutterLocalization.instance.getString(context, AppLocale.fetchConfigError).replaceAll('{errorDetails}', e.toString()))));
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  Future<void> _fetchParticipantsDetails(SharedListConfig config) async {
    if (config.authorizedUserIds.isEmpty) {
      setState(() => _authorizedUserDetails = []);
      return;
    }
    setState(() => _isLoadingParticipants = true);
    try {
      final users = await FirebaseRepoInteractor.instance.getUsersDetails(config.authorizedUserIds.keys.toList());
      if (mounted) {
        setState(() => _authorizedUserDetails = users);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(FlutterLocalization.instance.getString(context, AppLocale.fetchParticipantsError).replaceAll('{errorDetails}', e.toString()))));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingParticipants = false);
      }
    }
  }


  @override
  void dispose() {
    _shortLinkController.dispose();
    super.dispose();
  }

  void _onCopyLink() {
    if (_currentShareLink.isNotEmpty && _currentShareLink != FlutterLocalization.instance.getString(context, AppLocale.notSharedYet) && !_currentShareLink.startsWith("Error:")) {
      Clipboard.setData(ClipboardData(text: _currentShareLink));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FlutterLocalization.instance.getString(context, AppLocale.linkCopiedToClipboard))),
      );
    }
  }

  Future<void> _onSaveOrUpdateShare() async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FlutterLocalization.instance.getString(context, AppLocale.loginToSharePrompt))),
      );
      return;
    }

    final desiredPath = _shortLinkController.text.trim();
    // Basic validation (conceptual) - Firebase function might do more robust checks
    if (desiredPath.isNotEmpty && !RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(desiredPath)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(FlutterLocalization.instance.getString(context, AppLocale.linkPathInvalid))),
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
        _existingConfig = await FirebaseRepoInteractor.instance.getSharedListConfigById(widget.categoryId);
        setState(() {
          if (_existingConfig != null) {
            _shortLinkController.text = _existingConfig!.shortLinkPath; // Controller should reflect the *actual* path
            _currentShareLink = _getFullShareUrl(_existingConfig!.shortLinkPath);
            // No need to check adminUserId here for _shortLinkController.text,
            // createOrUpdateSharedList returns the definitive resultingShortLinkPath.
            // If desiredPath was empty, resultingShortLinkPath is the generated one.
            // If desiredPath was provided, resultingShortLinkPath is the validated (possibly suffixed) one.
            _shortLinkController.text = resultingShortLinkPath;
          } else {
             _shortLinkController.text = resultingShortLinkPath;
             _currentShareLink = _getFullShareUrl(resultingShortLinkPath);
          }
          _isEditingLink = false;
          _isLoading = false;
        });
        if (_existingConfig != null) _fetchParticipantsDetails(_existingConfig!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FlutterLocalization.instance.getString(context, AppLocale.shareSettingsUpdated))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${FlutterLocalization.instance.getString(context, AppLocale.shareError)}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayLink = _isLoading
        ? FlutterLocalization.instance.getString(context, AppLocale.loading)
        : _currentShareLink;
    if (!_isLoading && displayLink.isEmpty) {
        displayLink = FlutterLocalization.instance.getString(context, AppLocale.notSharedYet);
    }

    return AlertDialog(
      title: Text(FlutterLocalization.instance.getString(context, AppLocale.shareDialogTitle).replaceAll('{categoryName}', widget.categoryName)),
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
                      "${FlutterLocalization.instance.getString(context, AppLocale.shareableLink)} $displayLink",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (displayLink != FlutterLocalization.instance.getString(context, AppLocale.notSharedYet) && displayLink != FlutterLocalization.instance.getString(context, AppLocale.loading) && !displayLink.startsWith("Error:"))
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: FlutterLocalization.instance.getString(context, AppLocale.copyLinkButton),
                      onPressed: _onCopyLink,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shortLinkController,
                decoration: InputDecoration(
                  hintText: FlutterLocalization.instance.getString(context, AppLocale.customLinkPathHint),
                  labelText: FlutterLocalization.instance.getString(context, AppLocale.customLinkPathHint),
                  suffixIcon: IconButton(
                      icon: Icon(_shortLinkController.text.isNotEmpty ? Icons.clear : Icons.edit_note),
                      tooltip: _shortLinkController.text.isNotEmpty ? FlutterLocalization.instance.getString(context, AppLocale.clearInput) : FlutterLocalization.instance.getString(context, AppLocale.editSuffixTooltip),
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
                FlutterLocalization.instance.getString(context, AppLocale.authorizedUsersSectionTitle),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _isLoadingParticipants
                ? Center(child: CircularProgressIndicator())
                : (_authorizedUserDetails.isEmpty
                    ? Text(FlutterLocalization.instance.getString(context, AppLocale.noAuthorizedUsers))
                    : Column(
                        children: _authorizedUserDetails.map((user) {
                          bool isCurrentUserAdmin = _existingConfig?.adminUserId == FirebaseAuth.instance.currentUser?.uid;
                          bool isThisUserTheAdmin = user.id == _existingConfig?.adminUserId;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                                  ? NetworkImage(user.profilePictureUrl!)
                                  : null,
                              child: (user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty)
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user.name ?? FlutterLocalization.instance.getString(context, AppLocale.unknownUser)),
                            subtitle: isThisUserTheAdmin ? Text(FlutterLocalization.instance.getString(context, AppLocale.adminText)) : null,
                            trailing: (isCurrentUserAdmin && !isThisUserTheAdmin && FirebaseAuth.instance.currentUser?.uid != user.id)
                                ? IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                                    tooltip: FlutterLocalization.instance.getString(context, AppLocale.removeUserButtonTooltip),
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
          child: Text(FlutterLocalization.instance.getString(context, AppLocale.cancelButtonText)),
          onPressed: _isLoading || _isLoadingParticipants ? null : () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _isLoading || _isLoadingParticipants ? null : _onSaveOrUpdateShare,
          child: _isLoading
              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
              : Text(
                 (_existingConfig != null && _existingConfig!.shortLinkPath.isNotEmpty && !_isEditingLink)
                    ? FlutterLocalization.instance.getString(context, AppLocale.updateShareButton)
                    : FlutterLocalization.instance.getString(context, AppLocale.saveShareButton)
                ),
        ),
      ],
    );
  }

  Future<void> _removeUserFromSharedList(String userIdToRemove) async {
    if (_existingConfig == null || _existingConfig!.adminUserId != FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(FlutterLocalization.instance.getString(context, AppLocale.adminRequiredToRemoveUser))));
      return;
    }

    final AppUser.User? userToRemoveDetails = _authorizedUserDetails.firstWhere((u) => u.id == userIdToRemove, orElse: () => AppUser.User(email: FlutterLocalization.instance.getString(context, AppLocale.unknownUser), imageURL: "", name: FlutterLocalization.instance.getString(context, AppLocale.unknownUser)));
    final String userNameToRemove = userToRemoveDetails?.name ?? FlutterLocalization.instance.getString(context, AppLocale.unknownUser);


    bool? confirmed = await DialogHelper.showAlertDialog(
        context,
        FlutterLocalization.instance.getString(context, AppLocale.removeUserConfirmationTitle),
        FlutterLocalization.instance.getString(context, AppLocale.removeUserConfirmationMessage).replaceAll('{userName}', userNameToRemove),
        () => Navigator.of(context, rootNavigator: true).pop(true),
        () => Navigator.of(context, rootNavigator: true).pop(false),
    );


    if (confirmed == true) {
      setState(() => _isLoadingParticipants = true);

      _existingConfig!.authorizedUserIds.remove(userIdToRemove);

      bool success = await FirebaseRepoInteractor.instance.updateSharedListConfig(_existingConfig!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(FlutterLocalization.instance.getString(context, AppLocale.userRemovedSuccess).replaceAll('{userName}', userNameToRemove))),
          );
          _fetchParticipantsDetails(_existingConfig!);
        } else {
           _existingConfig!.authorizedUserIds[userIdToRemove] = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(FlutterLocalization.instance.getString(context, AppLocale.userRemovedError).replaceAll('{userName}', userNameToRemove))),
          );
        }
        setState(() => _isLoadingParticipants = false);
      }
    }
  }

}
