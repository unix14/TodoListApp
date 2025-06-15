import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_example/common/DialogHelper.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/date_extensions.dart';
import 'package:flutter_example/common/dialog_extensions.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/common/stub_data.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/mixin/pwa_installer_mixin.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Already present, ensure it stays
import 'package:flutter_example/models/shared_list_config.dart'; // Already present, ensure it stays
import 'package:flutter_example/widgets/share_list_dialog.dart'; // Already present, ensure it stays
// import 'package:sum_todo/generated/l10n.dart'; // Removed S class import
import 'package:flutter_example/screens/onboarding.dart';
import 'package:flutter_example/screens/settings.dart';
import 'package:flutter_example/widgets/rounded_text_input_field.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:html' as html;
import 'package:home_widget/home_widget.dart';

import 'onboarding.dart';

const String kRandomTaskMenuButtonName = 'randomTask';
const String kRenameCategoryMenuButtonName = 'rename_category';
const String kDeleteCategoryMenuButtonName = 'delete_category';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with PWAInstallerMixin, TickerProviderStateMixin {
  String inputText = "";
  bool enteredAtLeast1Todo = false;

  List<TodoListItem> items = [];
  late Future<List<TodoListItem>> _loadingData;

  TabController? _tabController;
  List<String> _categories = []; // Will be initialized in didChangeDependencies
  List<String> _customCategories = [];
  bool _isPromptingForCategory = false;

  TodoListItem? _editingTodo; // New state variable for currently edited item
  late TextEditingController _textEditingController; // Controller for inline editing

  bool isEditMode(TodoListItem todoItem) {
    return _editingTodo == todoItem; // Simplified edit mode check
  }

  // int itemOnEditIndex = -1; // Removed

  // Add a variable to control the opacity of the FloatingActionButton
  double fabOpacity = fabOpacityOff;

  final FocusNode _todoLineFocusNode = FocusNode();

  //todo refactor and extract code to widgets

  bool isLoading = true;

  late RoundedTextInputField todoInputField = RoundedTextInputField(
    hintText: FlutterLocalization.instance.getString(context, AppLocale.enterTodoTextPlaceholder),
    onChanged: (newValue) {
      setState(() {
        inputText = newValue;
        fabOpacity = newValue.isNotEmpty ? 1 : fabOpacityOff;
        enteredAtLeast1Todo = true;
      });
    },
    focusNode: _todoLineFocusNode,
    callback: () {
      print("Clicked enter");
      _onAddItem();
    },
  );

  /// Ads
  BannerAd? myBanner;
  AdWidget? adWidget;
  late AdListener listener;

  //init ads here
  void initAds() {
    listener = AdListener(
      // Called when an ad is successfully received.
      onAdLoaded: (Ad ad) {
        myBanner = ad as BannerAd;

        // print('Ad loaded.');
      },
      // Called when an ad request failed.
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        ad.dispose();
        print('Ad failed to load: $error');
      },
      // Called when an ad opens an overlay that covers the screen.
      onAdOpened: (Ad ad) => print('Ad opened.'),
      // Called when an ad removes an overlay that covers the screen.
      onAdClosed: (Ad ad) => print('Ad closed.'),
      // Called when an ad is in the process of leaving the application.
      onApplicationExit: (Ad ad) => print('Left application.'),
    );

    myBanner = BannerAd(
      adUnitId: kDebugMode ? kAdUnitIdDebug : kAdUnitIdProd,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener,
    );
    myBanner?.load();
    if (myBanner != null) {
      adWidget = AdWidget(ad: myBanner!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize categories and TabController here because context is available
    // and AppLocale needs it.
    _initializeTabs();
    // Load ad after build is complete
    Future.delayed(Duration.zero, () {
      myBanner?.load();
    });
  }

  Future<void> _initializeTabs() async {
    // Store the current tab index to restore it after re-initialization
    int previousIndex = _tabController?.index ?? 0;

    // Dispose old controller if exists BEFORE async operations
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    _tabController = null; // Set to null immediately

    // Perform async operation
    _customCategories = await EncryptedSharedPreferencesHelper.loadCategories();

    // This part should be synchronous and use the updated context from didChangeDependencies
    List<String> newCategories = [
      AppLocale.all.getString(context), // This uses the potentially new context
      ..._customCategories
    ];

    // Ensure previousIndex is valid for the new categories length
    // The TabController length will be newCategories.length + 1 (for the '+' tab)
    // So, valid indices for actual categories are 0 to newCategories.length - 1
    // and the '+' tab will be at index newCategories.length.
    if (previousIndex >= newCategories.length + 1) {
      previousIndex = 0; // Default to first tab if out of bounds
    }

    // If previous index was the '+' tab (which is at newCategories.length after new list is formed)
    // or if it points to an index that would be the '+' tab in the new setup.
    // For example, if newCategories is empty, previousIndex could be 0, which is the '+' tab.
    // If newCategories has 1 item, prevInd 1 is '+'. If 2 items, prevInd 2 is '+'.
    if (previousIndex == newCategories.length) {
       // If the previous tab was the '+' icon, default to the first actual category.
       // If there are no actual categories, it will correctly be 0 (which will be the '+' tab).
       previousIndex = 0;
    }
    // A simpler check: if previousIndex would now point to the '+' tab or beyond, reset to 0.
    // The maximum valid index for an *actual category tab* is `newCategories.length - 1`.
    // If `newCategories` is empty, this results in -1, so `previousIndex` should be 0.
    // The `TabController` will have `newCategories.length + 1` tabs.
    // `initialIndex` must be between 0 and `newCategories.length`.
    if (previousIndex > newCategories.length) { // If it's beyond the '+' tab index
        previousIndex = 0;
    }
    // If newCategories is empty, previousIndex must be 0 (the '+' tab).
    if (newCategories.isEmpty) {
        previousIndex = 0;
    }


    TabController newTabController = TabController(
      length: newCategories.length + 1, // +1 for the '+' tab
      vsync: this,
      initialIndex: previousIndex,
    );
    newTabController.addListener(_handleTabSelection);

    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _categories = newCategories;
        _tabController = newTabController;
      });
    } else {
      // If not mounted, dispose the newly created controller to avoid leaks
      newTabController.dispose();
    }
  }

  void _handleTabSelection() {
    if (_tabController == null) return;
    if (_isPromptingForCategory) return;

    // Check if the controller is still valid (not disposed)
    // and if the index is for the "+" button
    if (_tabController!.index == _categories.length) {
      final previousIndex = _tabController!.previousIndex;

      // It's crucial to ensure that the tab index is changed *before* showing the dialog,
      // so the UI doesn't get stuck on the "+" tab visually.
      // However, changing it immediately might cause a flicker if the dialog is cancelled.
      // The postFrameCallback helps schedule the dialog prompt after the current build cycle.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if the tab controller is still at the "+" tab before prompting
        // This can prevent issues if multiple taps occur quickly or state changes rapidly
        if (_tabController!.index == _categories.length) {
          _isPromptingForCategory = true;
          _promptForNewCategory(selectedIndexToRestore: previousIndex);
        }
      });
    } else {
       if (_tabController!.indexIsChanging) {
         setState(() {
           // Handle regular tab changes, e.g., save the index
         });
       }
    }
  }


  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    myBanner?.dispose();
    _todoLineFocusNode.dispose(); // Dispose of the FocusNode
    _textEditingController.dispose(); // Dispose the text controller
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(); // Initialize the controller
    _loadingData = loadList();
    if (false) initAds();
    initializeInstallPrompt();
    // _initializeTabs will be called from didChangeDependencies
  }

  void _setEditingTodo(TodoListItem? todo) {
    setState(() {
      _editingTodo = todo;
      if (todo != null) {
        _textEditingController.text = todo.text;
        // Optionally, request focus for the TextField if it's now visible.
        // This might require passing a FocusNode to the TextField in getListTile.
      } else {
        _textEditingController.clear();
      }
    });
  }

  bool _isCurrentCategoryCustom() {
    if (_tabController == null || _categories.isEmpty) {
      return false;
    }
    // Ensure index is valid for _categories before accessing.
    // _tabController.index can be out of bounds if tabs are being re-initialized,
    // or if it points to the "+" button which is not a category in _categories list.
    if (_tabController!.index < 0 || _tabController!.index >= _categories.length) {
      return false;
    }
    // Check if the selected category is NOT the "All" category.
    return _categories[_tabController!.index] != AppLocale.all.getString(context);
  }

  @override
  Widget build(BuildContext context) {
    // Ensure FlutterLocalization is initialized before using it.
    // This typically happens in main.dart or a top-level widget.
    // For this example, we assume it's initialized.
    final localization = FlutterLocalization.instance;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(localization.getString(context, AppLocale.title)),
        bottom: _tabController == null
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  ..._categories.map((String name) => Tab(text: name)).toList(), // Category names are already localized or user-defined
                  Tab(icon: Tooltip(message: localization.getString(context, AppLocale.addCategoryTooltip), child: const Icon(Icons.add))),
                ],
              ),
        actions: [
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == kInstallMenuButtonName) {
                      showInstallPrompt();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localization.getString(context, AppLocale.appIsInstalled))));
                    } else if (value == kArchiveMenuButtonName) {
                      showArchivedTodos();
                    } else if (value == kLoginButtonMenu) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OnboardingScreen()));
                    } else if (value == kSettingsMenuButtonName) {
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()));
                      if (result == true && mounted) {
                        setState(() {
                          _loadingData = loadList();
                        });
                        await _initializeTabs();
                        if (mounted && _tabController != null && _tabController!.length > 0) {
                           _tabController!.animateTo(0);
                        }
                      }
                    } else if (value == kRandomTaskMenuButtonName) {
                      _showRandomTask();
                    } else if (value == kRenameCategoryMenuButtonName) {
                      if (_isCurrentCategoryCustom()) {
                        final currentCategoryName = _categories[_tabController!.index];
                        _promptRenameCategory(currentCategoryName);
                      }
                    } else if (value == kDeleteCategoryMenuButtonName) {
                      if (_isCurrentCategoryCustom()) {
                        final currentCategoryName = _categories[_tabController!.index];
                        DialogHelper.showAlertDialog(
                          context,
                          localization.getString(context, AppLocale.deleteCategoryConfirmationTitle),
                          localization.getString(context, AppLocale.deleteCategoryConfirmationMessage).replaceAll('{categoryName}', currentCategoryName),
                          () {
                            Navigator.of(context).pop();
                            setState(() {
                              _customCategories.removeWhere((cat) => cat.toLowerCase() == currentCategoryName.toLowerCase());
                              for (var item in items) {
                                if (item.category == currentCategoryName) {
                                  item.category = null;
                                }
                              }
                              EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
                                HomeWidget.updateWidget(
                                  name: 'com.eyalya94.tools.todoLater.TodoWidgetProvider',
                                  iOSName: 'TodoWidgetProvider',
                                );
                                print('[HomeWidget] Sent update request to widget provider after deleting category.');
                              _updateList();
                              _initializeTabs().then((_) {
                                if (mounted && _tabController != null) {
                                   _tabController!.index = 0;
                                }
                              });
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(localization.getString(context, AppLocale.categoryDeletedSnackbar).replaceAll('{categoryName}', currentCategoryName)),
                            ));
                          },
                          () {
                            Navigator.of(context).pop();
                          },
                        );
                      }
                    }
                    // Cases for kShareCategoryMenuButtonName and kJoinSharedListMenuButtonName
                    // were added in previous steps and assumed to be here.
                    // Their dialogs will be localized separately if needed.
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuItem<String>> popupMenuItems = [];
                    if (isLoggedIn == false) { // Assuming isLoggedIn is still managed
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kLoginButtonMenu,
                        child: Row(children: [ const Icon(Icons.login, color: Colors.blue), const SizedBox(width: 8.0), Text(localization.getString(context, AppLocale.login))]),
                      ));
                    }
                    if (isInstallable()) {
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kInstallMenuButtonName,
                        child: Row(children: [const Icon(Icons.install_mobile, color: Colors.blue), const SizedBox(width: 8.0), Text(localization.getString(context, AppLocale.installApp))]),
                      ));
                    }
                    if (items.any((item) => item.isArchived)) {
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kArchiveMenuButtonName,
                        child: Row(children: [const Icon(Icons.archive, color: Colors.blue), const SizedBox(width: 8.0), Text(localization.getString(context, AppLocale.archive))]),
                      ));
                    }
                    if (_isCurrentCategoryCustom()) {
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kRenameCategoryMenuButtonName,
                        child: Row(children: [const Icon(Icons.edit, color: Colors.blue), const SizedBox(width: 8.0), Text(localization.getString(context, AppLocale.renameCategoryMenuButton))]),
                      ));
                      // Add "Share" and "Delete" for custom categories as per existing logic
                       popupMenuItems.add(PopupMenuItem<String>(
                        value: kShareCategoryMenuButtonName, // This was added in a prior step
                        child: Row(children: [const Icon(Icons.share, color: Colors.blue), const SizedBox(width: 8.0), Text(localization.getString(context, AppLocale.shareCategoryButtonTooltip))]),
                      ));
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kDeleteCategoryMenuButtonName,
                        child: Row(children: [const Icon(Icons.delete_outline, color: Colors.red), const SizedBox(width: 8.0), Text(localization.getString(context, AppLocale.deleteCategoryMenuButton), style: const TextStyle(color: Colors.red))]),
                      ));
                    }
                    popupMenuItems.add(PopupMenuItem<String>(
                      value: kRandomTaskMenuButtonName,
                      child: Row(children: [const Icon(Icons.shuffle, color: Colors.blue), const SizedBox(width: 8.0), Text(localization.getString(context, AppLocale.randomTaskMenuButton))]),
                    ));
                     if (FirebaseAuth.instance.currentUser != null) { // Join list option
                        popupMenuItems.add(PopupMenuItem<String>(
                        value: kJoinSharedListMenuButtonName, // This was added in a prior step
                        child: Row(children: [const Icon(Icons.group_add, color: Colors.blue), const SizedBox(width: 8.0), Text(localization.getString(context, AppLocale.simulateOpenLinkButton))]),
                      ));
                    }
                    popupMenuItems.add(PopupMenuItem<String>(
                      value: kSettingsMenuButtonName,
                      child: Row(children: [const Icon(Icons.settings_outlined, color: Colors.blue), const SizedBox(width: 8.0), Text(localization.getString(context, AppLocale.settings))]),
                    ));
                    return popupMenuItems;
                  },
                ),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _tabController == null || _categories.isEmpty // _categories is still used by TabBarView here
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _categories.map((String categoryName) { // Iterating old _categories
                      // This logic needs to be fully replaced by _TabData and StreamBuilder/FutureBuilder logic
                      // For now, just localizing existing text within this old structure.
                      return FutureBuilder<List<TodoListItem>>(
                        future: _loadingData,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else {
                            final allLoadedItems = snapshot.data ?? [];
                            items = allLoadedItems;
                            List<TodoListItem> displayedItems;
                            if (categoryName == localization.getString(context, AppLocale.all)) {
                              displayedItems = allLoadedItems.reversed.where((item) => !item.isArchived).toList();
                            } else {
                              displayedItems = allLoadedItems.reversed.where((item) => !item.isArchived && item.category == categoryName).toList();
                            }

                            if (categoryName == localization.getString(context, AppLocale.all) && displayedItems.isEmpty) {
                              final List<String> motivationalKeys = [AppLocale.motivationalSentence1, AppLocale.motivationalSentence2, AppLocale.motivationalSentence3, AppLocale.motivationalSentence4, AppLocale.motivationalSentence5];
                              final randomKey = motivationalKeys[Random().nextInt(motivationalKeys.length)];
                              return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(localization.getString(context, randomKey), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.grey, fontStyle: FontStyle.italic))));
                            }

                            if (displayedItems.isNotEmpty) {
                              String taskCountString;
                              if (displayedItems.length == 1) {
                                taskCountString = localization.getString(context, AppLocale.tasksCountSingular);
                              } else {
                                taskCountString = localization.getString(context, AppLocale.tasksCount).replaceAll('{count}', displayedItems.length.toString());
                              }
                              return Column(children: [
                                Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Text(taskCountString, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.0, color: Colors.blueGrey, fontWeight: FontWeight.w500))),
                                Expanded(child: ListView.builder(itemCount: displayedItems.length, itemBuilder: (context, position) => getListTile(displayedItems[position]))),
                              ]);
                            } else {
                              return ListView.builder(itemCount: 0, itemBuilder: (context, position) => Container());
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: adWidget,
            width: myBanner?.size.width.toDouble() ?? 0,
            height: myBanner?.size.height.toDouble() ?? 0,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                todoInputField,
                SizedBox(
                  height: 69.0,
                  width: enteredAtLeast1Todo ? 80 : 0,
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (enteredAtLeast1Todo)
          ? Opacity(
              opacity: fabOpacity,
              child: FloatingActionButton(
                onPressed: () {
                  _onAddItem();
                },
                tooltip: localization.getString(context, AppLocale.addTodo), // Changed to AppLocale.addTodo
                child: const Icon(Icons.add),
              ),
            )
          : Container(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _onAddItem() {
    if (inputText.isNotEmpty) {
      String? currentCategory;
      if (_tabController != null && _categories.isNotEmpty) {
        final selectedCategoryName = _categories[_tabController!.index];
        if (selectedCategoryName != AppLocale.all.getString(context)) {
          currentCategory = selectedCategoryName;
        }
      }

      setState(() {
        items.add(TodoListItem(inputText.trim(), category: currentCategory));
        _updateList(); // This should persist the full 'items' list

        // Reload data to reflect in FutureBuilder, or manage state more granularly
        // For simplicity, we can rely on setState and FutureBuilder re-running.
        // If _loadingData is not re-fetched, new items might not show until next full load.
        // A better approach might be to update the snapshot data directly or re-fetch.
        // For now, we assume _updateList and subsequent setState will refresh UI.

        inputText = "";
        todoInputField.clear();
        fabOpacity = fabOpacityOff;
      });
    } else {
      DialogHelper.showAlertDialog(
          context,
          localization.getString(context, AppLocale.emptyTodoDialogTitle),
          localization.getString(context, AppLocale.emptyTodoDialogMessage),
          () {
        Navigator.of(context).pop();
      }, null);
    }
  }

  void _updateList() async {
    // Convert the current list to JSON
    var listAsStr = jsonEncode(items);
    await EncryptedSharedPreferencesHelper.setString(kAllListSavedPrefs, listAsStr);
    print("update list :" + listAsStr);

    // todo update realtime DB if logged in

    if (isLoggedIn && currentUser?.uid.isNotEmpty == true) {
      if (myCurrentUser == null) {
        myCurrentUser =
            await FirebaseRepoInteractor.instance.getUserData(currentUser!.uid);
      }
      myCurrentUser!.todoListItems = items;

      var didSuccess =
          await FirebaseRepoInteractor.instance.updateUserData(myCurrentUser!);
      if (didSuccess == true) {
        print("success save to DB");
      }
    }

    // Notify the widget to update
    HomeWidget.updateWidget(
      name: 'com.eyalya94.tools.todoLater.TodoWidgetProvider', // Fully qualified name of your AppWidgetProvider
      iOSName: 'TodoWidgetProvider', // iOSName if you implement for iOS
    );
    print('[HomeWidget] Sent update request to widget provider after updating list.');
  }

  Future<List<TodoListItem>> loadList() async {
    isLoading = true;
    items = await _loadList();
    await archiveTodos();
    isLoading = false;
    return items;
  }

  void refreshList() async {
    isLoading = true;
    await archiveTodos();
    isLoading = false;
  }

  void showArchivedTodos() async {
    // Use archivedTodos to display archived todos.
    // Display the archived todos using an AlertDialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Display the archived todos using your preferred UI, e.g., a dialog, a new page, etc.
            final List<TodoListItem> archivedTodos =
                items.where((item) => item.isArchived).toList();

            return AlertDialog(
              title: Text(AppLocale.archivedTodos.getString(context)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: archivedTodos.length,
                        itemBuilder: (context, index) {
                          final todo = archivedTodos[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                todo.isChecked = !todo.isChecked;
                                todo.dateTime = DateTime.now();
                                refreshList();
                                // _updateList();
                              });
                            },
                            child: SizedBox(
                              child: ListTile(
                                leading: Checkbox(
                                  value: todo.isChecked,
                                  onChanged: (bool? value) {
                                    // await archiveTodos();
                                    setState(() {
                                      todo.isChecked = !todo.isChecked;
                                      todo.dateTime = DateTime.now();
                                      // _updateList();
                                      refreshList();
                                    });
                                  },
                                ),
                                title: Text(
                                  todo.text,
                                  style: TextStyle(
                                    decoration: todo.isChecked
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                subtitle: Text(
                                  getFormattedDate(todo.dateTime.toString(), context),
                                  style: TextStyle(
                                    decoration: todo.isChecked
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                trailing: TextButton(
                                    onPressed: () {
                                      DialogHelper.showAlertDialog(
                                          context,
                                          AppLocale.doUwant2Delete.getString(context),
                                          AppLocale.thisCantBeUndone.getString(context), () {
                                        // dismiss dialog
                                        setState(() {
                                          items.remove(todo);
                                          // itemOnEditIndex = -1; // Removed
                                          if (_editingTodo == todo) {
                                            _setEditingTodo(null); // Clear editing state if deleted item was being edited
                                          }
                                          _updateList();
                                        });
                                        Navigator.of(context).pop();
                                      }, () {
                                        // Cancel
                                        Navigator.of(context).pop(); // dismiss dialog
                                      });
                                    },
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.black12,
                                    )),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Text(AppLocale.archivedTodosSubtitle.getString(context)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    setState(() {});
                  },
                  child: Text(AppLocale.close.getString(context)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> archiveTodos() async {
    final List<TodoListItem> completedTodos = List.from(items);

    for (final completedTodo in completedTodos) {
      completedTodo.isArchived = completedTodo.isEligibleForArchiving();
    }
    // items.removeWhere((item) => item.isArchived);
    _updateList();
  }

  //todo refactor to somewhere else
  Future<List<TodoListItem>> _loadList() async {
    /// todo refactor to seperate classes

    /// fetch from shared Preferences
    var listStr = await EncryptedSharedPreferencesHelper.getString(kAllListSavedPrefs) ?? "";
    print("load list :" + listStr);

    if (listStr.isNotEmpty) {
      List<dynamic> decodedList = jsonDecode(listStr);
      List<TodoListItem> sharedPrefsTodoList = decodedList.isNotEmpty ?
      decodedList.map((item) => TodoListItem.fromJson(item)).toList() : [];

      if (isLoggedIn && currentUser != null) {
        /// fetch from firebase
        if (myCurrentUser == null) {
          // Load user data if not already loaded
          myCurrentUser = await FirebaseRepoInteractor.instance
              .getUserData(currentUser!.uid);
          print("Loading first time the data from the DB");
        }

        print("the result for ${currentUser!.uid} is ${myCurrentUser?.todoListItems?.length ?? -1}");
        if (myCurrentUser != null && myCurrentUser?.todoListItems != null) {
          print("Loading from the DB");

          if (sharedPrefsTodoList.isNotEmpty) {
            var didMerged = false;
            // Merge the two lists
            for (var item in sharedPrefsTodoList) {
              // check by parameters
              if (!myCurrentUser!.todoListItems!.contains(item) &&
                  !myCurrentUser!.todoListItems!.any((element) =>
                      element.text == item.text &&
                      element.isArchived == item.isArchived)) {
                myCurrentUser!.todoListItems!.add(item);
                didMerged = true;
              }
            }

            if (didMerged) {
              // update firebase
              var didSuccess = await FirebaseRepoInteractor.instance
                  .updateUserData(myCurrentUser!);
              if (didSuccess == true) {
                print("success save to DB");
              } else {
                print("failed save to DB");
              }
              // update shared prefs
              await EncryptedSharedPreferencesHelper.setString(
                  kAllListSavedPrefs, jsonEncode(myCurrentUser!.todoListItems));
            }
          }

          return myCurrentUser!.todoListItems!;
        }
      }
      return sharedPrefsTodoList;
    } else {
      /// fetch from firebase
      if (myCurrentUser == null && currentUser != null) {
        // Load user data if not already loaded
        myCurrentUser =
            await FirebaseRepoInteractor.instance.getUserData(currentUser!.uid);
      }
      if (myCurrentUser != null && myCurrentUser?.todoListItems != null) {
        print("Loading from the DB 2");
        return myCurrentUser!.todoListItems!;
      }
      return StubData.getInitialTodoList(context);
    }
  }

  Widget getListTile(TodoListItem currentTodo) {
    // var currentTodoEditInput = RoundedTextInputField( ... ); // This seems to be for the old edit mode. Will remove/replace.

    return InkWell(
      onLongPress: () {
        if (_editingTodo == currentTodo) { // If already editing this item
          _saveTodo(currentTodo, _textEditingController.text); // Save current changes
        } else { // Not editing this one, or not editing at all
          if (_editingTodo != null) { // If editing another item
            _saveTodo(_editingTodo!, _textEditingController.text); // Save changes to the other item
            // _setEditingTodo(null); // No longer needed here as _saveTodo handles it
          }
          _showTodoContextMenu(currentTodo); // Then show context menu for current one
        }
      },
      onTap: () {
        if (isEditMode(currentTodo)) {
          // Tapping an item already in inline edit mode: do nothing here.
          // Focus should be handled by the TextField itself or its autofocus.
          // Saving is done via the leading Save icon or TextField's onSubmitted.
        } else if (_editingTodo != null) { // If editing a DIFFERENT item
          _saveTodo(_editingTodo!, _textEditingController.text); // Save the other one
          // _setEditingTodo(null); // _saveTodo calls this
          // THEN, allow the tap to toggle the checkbox of the current (tapped) item
          toggleCheckBox(currentTodo, !currentTodo.isChecked);
        } else { // Not editing any item
          toggleCheckBox(currentTodo, !currentTodo.isChecked);
        }
      },
      child: SizedBox(
        child: isEditMode(currentTodo)
            // INLINE EDIT MODE UI
            ? ListTile(
                leading: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    _saveTodo(currentTodo, _textEditingController.text);
                  },
                ),
                title: TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppLocale.editTaskHintText.getString(context),
                  ),
                  onSubmitted: (newText) {
                    _saveTodo(currentTodo, newText);
                  },
                ),
                trailing: null, // No trailing widget in edit mode
                subtitle: null, // No subtitle in edit mode
              )
            // NON-EDIT MODE UI (from Part 1)
            : ListTile(
                leading: Checkbox(
                  value: currentTodo.isChecked,
                  onChanged: (bool? value) {
                     if (_editingTodo != null && _editingTodo != currentTodo) {
                        _saveTodo(_editingTodo!, _textEditingController.text);
                        // _setEditingTodo(null); // _saveTodo calls this
                    } else if (_editingTodo == currentTodo) {
                        // This state should ideally not be reachable if checkbox is only shown in non-edit mode.
                        _saveTodo(currentTodo, _textEditingController.text);
                        return;
                    }
                    toggleCheckBox(currentTodo, value);
                  },
                ),
                title: Text(
                  currentTodo.text,
                  style: TextStyle(
                    decoration: currentTodo.isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Text(
                  getFormattedDate(currentTodo.dateTime.toString(), context),
                  style: TextStyle(
                    decoration: currentTodo.isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                trailing: null,
              ),
      ),
    );
  }

  void _saveTodo(TodoListItem todo, String newText) {
    if (newText.trim().isEmpty) {
      // Optional: Show a snackbar or dialog if text is empty, or just don't save.
      // For now, let's prevent saving an empty todo and exit edit mode.
      _setEditingTodo(null);
      // Maybe delete if original was not empty and new is empty? For now, just revert.
      return;
    }
    setState(() {
      if (todo.text != newText.trim()) {
        todo.text = newText.trim();
        todo.dateTime = DateTime.now();
      }
      _updateList();
    });
    _setEditingTodo(null); // Exit edit mode after saving
  }


  void toggleCheckBox(TodoListItem currentTodo, bool? value) {
    // Ensure not to toggle if in edit mode for THIS item by tapping checkbox area (though checkbox is not shown)
    if (isEditMode(currentTodo)) return;

    // If editing another item, save it before toggling checkbox for current item
    if (_editingTodo != null && _editingTodo != currentTodo) {
       _saveTodo(_editingTodo!, _textEditingController.text);
    }
    _setEditingTodo(null); // Ensure exiting edit mode for any other item

    setState(() {
      currentTodo.isChecked = value ?? false;
      _updateList();
    });
  }

  // void toggleEditMode(TodoListItem currentTodo) { // Replaced by _setEditingTodo
  //   setState(() {
  //     if (itemOnEditIndex == -1) {
  //       var index = items.indexOf(currentTodo);
  //       itemOnEditIndex = index;
  //     } else {
  //       itemOnEditIndex = -1;
  //     }
  //   });
  // }

  // void updateTile(TodoListItem currentTodo, String todoText) { // Replaced by _saveTodo
  //   setState(() {
  //     var index = items.indexOf(currentTodo);
  //     var didChanged = false;
  //     if (todoText.isNotEmpty) {
  //       didChanged = currentTodo.text != todoText;
  //       currentTodo.text = todoText; // todo fix issues w updating the text
  //     }
  //     if (didChanged) {
  //       currentTodo.dateTime = DateTime.now();
  //     }
  //     items[index] = currentTodo;
  //     _updateList();
  //   });
  // }

  void deleteAll() {
    DialogHelper.showAlertDialog(context, AppLocale.areUsure.getString(context),
        AppLocale.deleteAllSubtext.getString(context),
        () {
      setState(() {
        items.clear();
        _updateList();
        Navigator.of(context).pop();
      });
    }, () {
      // Cancel
      Navigator.of(context).pop(); // dismiss dialog
    });
  }

  void _showRandomTask() {
    String currentCategoryName = AppLocale.all.getString(context); // Default to "All"
    if (_tabController != null && _tabController!.index < _categories.length) {
      currentCategoryName = _categories[_tabController!.index];
    }

    List<TodoListItem> availableTasks;
    if (currentCategoryName == AppLocale.all.getString(context)) {
      availableTasks = items
          .where((item) => !item.isArchived && !item.isChecked)
          .toList();
    } else {
      availableTasks = items
          .where((item) =>
              item.category == currentCategoryName &&
              !item.isArchived &&
              !item.isChecked)
          .toList();
    }

    if (availableTasks.isEmpty) {
      DialogHelper.showAlertDialog(
        context,
        AppLocale.noTasksAvailableDialogTitle.getString(context),
        AppLocale.noTasksAvailableDialogMessage.getString(context),
        () {
          Navigator.of(context).pop(); // dismiss dialog
        },
        null,
      );
    } else {
      final randomIndex = Random().nextInt(availableTasks.length);
      final randomTask = availableTasks[randomIndex];
      DialogHelper.showAlertDialog(
        context,
        AppLocale.randomTaskDialogTitle.getString(context),
        randomTask.text,
        () {
          Navigator.of(context).pop(); // dismiss dialog
        },
        null,
      );
    }
  }

  Future<String?> _promptForNewCategory({int? selectedIndexToRestore}) async {
    final TextEditingController categoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? newCategoryName; // To store the name of the category if added

    // Set _isPromptingForCategory at the beginning
    // It's important _isPromptingForCategory is true during the dialog display
    // setState(() { // Not strictly necessary to call setState just for this flag if no UI depends on it immediately
    //   _isPromptingForCategory = true;
    // });

    try {
      // The dialog's result will be the new category name or null
      newCategoryName = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(AppLocale.addCategoryDialogTitle.getString(dialogContext)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: ListBody(
                  children: <Widget>[
                    TextFormField(
                      controller: categoryController,
                      decoration: InputDecoration(hintText: AppLocale.categoryNameHintText.getString(dialogContext)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocale.categoryNameEmptyError.getString(dialogContext);
                        }
                        if (_customCategories.any((cat) => cat.toLowerCase() == value.trim().toLowerCase())) {
                          return AppLocale.categoryNameExistsError.getString(dialogContext);
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(AppLocale.cancelButtonText.getString(dialogContext)),
                onPressed: () {
                  Navigator.of(dialogContext).pop(null); // Dialog returns null
                },
              ),
              TextButton(
                child: Text(AppLocale.okButtonText.getString(dialogContext)),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newCategory = categoryController.text.trim();
                    // No setState here, state updates will be handled after dialog closes if category was added.
                    // This simplifies the dialog's responsibility to just returning the name.
                    Navigator.of(dialogContext).pop(newCategory); // Dialog returns the new category name
                  }
                },
              ),
            ],
          );
        },
      );

      // After the dialog closes, 'newCategoryName' holds the result.
      if (newCategoryName != null) {
        // If a category name was returned (not null), then proceed to update state.
        setState(() {
          _customCategories.add(newCategoryName!);
          EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
          // Notify the widget to update
          HomeWidget.updateWidget(
            name: 'com.eyalya94.tools.todoLater.TodoWidgetProvider',
            iOSName: 'TodoWidgetProvider',
          );
          print('[HomeWidget] Sent update request to widget provider after adding category.');

          _categories = [AppLocale.all.getString(context), ..._customCategories];

          final newCategoryIndexInCategories = _categories.lastIndexOf(newCategoryName!);

          _tabController?.removeListener(_handleTabSelection);
          _tabController?.dispose();
          _tabController = TabController(
            length: _categories.length + 1, // +1 for '+' tab
            vsync: this,
            initialIndex: newCategoryIndexInCategories,
          );
          _tabController!.addListener(_handleTabSelection);
          // _isPromptingForCategory is reset in finally
        });
      }
    } finally {
      // Ensure _isPromptingForCategory is reset regardless of outcome
      setState(() {
        _isPromptingForCategory = false;
      });
    }

    // Handle tab restoration if no category was added and an index was provided
    if (newCategoryName == null && selectedIndexToRestore != null && _tabController != null) {
      if (_tabController!.index == _categories.length && mounted) {
        // Check if current context is still valid before animating.
        // This ensures we only try to animate if the widget is still in the tree.
        _tabController!.animateTo(selectedIndexToRestore);
      }
    }

    return newCategoryName; // Return the new category name or null
  }

  void _showTodoContextMenu(TodoListItem todoItem) {
    // Ensure any active edit is saved before showing context menu for potentially different item
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        final localization = FlutterLocalization.instance;
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(localization.getString(bottomSheetContext, AppLocale.editMenuItem)),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _setEditingTodo(todoItem);
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: Text(localization.getString(bottomSheetContext, AppLocale.moveToCategoryMenuItem)),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _promptMoveToCategory(todoItem);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(localization.getString(bottomSheetContext, AppLocale.deleteMenuItem), style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _confirmDeleteItem(todoItem);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteItem(TodoListItem todoItem) {
     final localization = FlutterLocalization.instance;
     DialogHelper.showAlertDialog(
        context,
        localization.getString(context, AppLocale.doUwant2Delete),
        localization.getString(context, AppLocale.thisCantBeUndone),
        () {
      Navigator.of(context).pop();
      _setEditingTodo(null);
      setState(() {
        items.remove(todoItem);
        _updateList();
      });
    }, () {
      Navigator.of(context).pop();
    });
  }

  void _promptMoveToCategory(TodoListItem todoItem) async {
    final localization = FlutterLocalization.instance;
    List<String> availableCategories = List.from(_customCategories);

    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: Text(localization.getString(dialogContext, AppLocale.selectCategoryDialogTitle)),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: Text(localization.getString(dialogContext, AppLocale.uncategorizedCategory)),
            ),
            ...availableCategories.map((category) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, category),
                child: Text(category),
            )).toList(),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, kAddNewCategoryOption),
              child: Text(localization.getString(dialogContext, AppLocale.addNewCategoryMenuItem)),
            ),
          ],
        );
      },
    ).then((selectedCategoryNameOrAction) {
      if (selectedCategoryNameOrAction == kAddNewCategoryOption) {
        _promptForNewCategory().then((newlyCreatedCategoryName) {
          if (newlyCreatedCategoryName != null && newlyCreatedCategoryName.isNotEmpty) {
            setState(() { todoItem.category = newlyCreatedCategoryName; _updateList(); });
            _initializeTabs();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(localization.getString(context, AppLocale.itemMovedSnackbar).replaceAll('{categoryName}', newlyCreatedCategoryName)),
            ));
          }
        });
      } else {
        final selectedCategoryName = selectedCategoryNameOrAction as String?;
        if (selectedCategoryName != todoItem.category || (selectedCategoryName == null && todoItem.category != null) || (selectedCategoryName != null && todoItem.category == null) ) {
          bool categoryWasActuallySelected = !(selectedCategoryName == null && todoItem.category == null);
          if (categoryWasActuallySelected) {
            setState(() { todoItem.category = selectedCategoryName; _updateList(); });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(selectedCategoryName == null
                    ? localization.getString(context, AppLocale.itemUncategorizedSnackbar)
                    : localization.getString(context, AppLocale.itemMovedSnackbar).replaceAll('{categoryName}', selectedCategoryName)),
            ));
          }
        }
      }
    });
  }
  Future<String?> _promptRenameCategory(String oldCategoryName) async {
    final localization = FlutterLocalization.instance;
    final TextEditingController categoryController = TextEditingController(text: oldCategoryName);
    final formKey = GlobalKey<FormState>();
    String? newCategoryName;

    try {
      newCategoryName = await showDialog<String>(
        context: context, barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(localization.getString(dialogContext, AppLocale.renameCategoryDialogTitle)),
            content: SingleChildScrollView(child: Form(key: formKey, child: ListBody(children: <Widget>[
                    TextFormField(controller: categoryController, decoration: InputDecoration(hintText: localization.getString(dialogContext, AppLocale.categoryNameHintText)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return localization.getString(dialogContext, AppLocale.categoryNameEmptyError);
                        final newNameTrimmed = value.trim();
                        if (newNameTrimmed.toLowerCase() == localization.getString(dialogContext, AppLocale.all).toLowerCase()) return localization.getString(dialogContext, AppLocale.categoryNameExistsError);
                        if (newNameTrimmed.toLowerCase() != oldCategoryName.toLowerCase() && _customCategories.any((cat) => cat.toLowerCase() == newNameTrimmed.toLowerCase())) return localization.getString(dialogContext, AppLocale.categoryNameExistsError);
                        return null;
                      },
                    ),
            ])))),
            actions: <Widget>[
              TextButton(child: Text(localization.getString(dialogContext, AppLocale.cancelButtonText)), onPressed: () => Navigator.of(dialogContext).pop(null)),
              TextButton(child: Text(localization.getString(dialogContext, AppLocale.renameButtonText)), onPressed: () { if (formKey.currentState!.validate()) Navigator.of(dialogContext).pop(categoryController.text.trim()); }),
            ],
        ),
      );
      if (newCategoryName != null && newCategoryName != oldCategoryName) {
        setState(() {
          final oldNameIndex = _customCategories.indexWhere((cat) => cat.toLowerCase() == oldCategoryName.toLowerCase());
          if (oldNameIndex != -1) _customCategories[oldNameIndex] = newCategoryName!;
          for (var item in items) { if (item.category == oldCategoryName) item.category = newCategoryName; }
          EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
          HomeWidget.updateWidget(name: 'com.eyalya94.tools.todoLater.TodoWidgetProvider', iOSName: 'TodoWidgetProvider');
          _updateList(); _initializeTabs();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localization.getString(context, AppLocale.categoryRenamedSnackbar).replaceAll('{oldName}', oldCategoryName).replaceAll('{newName}', newCategoryName!))));
        });
      }
      return newCategoryName;
    } catch (e) {
      print("Error in _promptRenameCategory: $e"); return null;
    }
  }
  // Methods related to shared lists (from previous subtasks, ensure localization)
  void _showShareDialog(String categoryName, String categoryId) { /* ... uses ShareListDialog which is now localized ... */
      showDialog(context: context, builder: (BuildContext dialogContext) => ShareListDialog(categoryName: categoryName, categoryId: categoryId)
      ).then((_) => _initializeTabs()); // Refresh tabs after dialog closes
  }
  Future<void> _promptToJoinSharedList() async { /* ... uses AppLocale keys, ensure they are wrapped with localization.getString ... */
    final localization = FlutterLocalization.instance;
    final TextEditingController linkPathController = TextEditingController();
    final GlobalKey<FormFieldState<String>> formFieldKey = GlobalKey();
    final String? enteredPath = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(localization.getString(dialogContext, AppLocale.simulateOpenLinkButton)),
          content: TextFormField(key: formFieldKey, controller: linkPathController, decoration: InputDecoration(hintText: localization.getString(dialogContext, AppLocale.enterLinkPathHint)),
            validator: (value) => (value == null || value.trim().isEmpty) ? localization.getString(dialogContext, AppLocale.linkPathInvalid) : null,
          ),
          actions: <Widget>[
            TextButton(child: Text(localization.getString(dialogContext, AppLocale.cancelButtonText)), onPressed: () => Navigator.of(dialogContext).pop(null)),
            TextButton(child: Text(localization.getString(dialogContext, AppLocale.joinButtonText)), onPressed: () { if (formFieldKey.currentState!.validate()) Navigator.of(dialogContext).pop(linkPathController.text.trim()); }),
          ],
      ),
    );
    if (enteredPath != null && enteredPath.isNotEmpty) {
      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserUid == null) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localization.getString(context, AppLocale.loginToJoinPrompt))));
        return;
      }
      try {
        final SharedListConfig? joinedConfig = await FirebaseRepoInteractor.instance.joinSharedList(enteredPath, currentUserUid);
        if (mounted && joinedConfig != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localization.getString(context, AppLocale.joinListSuccess).replaceAll('{listName}', joinedConfig.originalCategoryName))));
          _initializeTabs(); // Refresh tabs
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localization.getString(context, AppLocale.joinListError))));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${localization.getString(context, AppLocale.joinListError)}: $e")));
      }
    }
  }
}

// Define a constant for the "Add New Category" option to avoid magic strings
const String kAddNewCategoryOption = 'add_new_category_option_val'; // Made it more unique