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
import 'package:flutter_example/screens/onboarding.dart';
import 'package:flutter_example/screens/settings.dart';
import 'package:flutter_example/widgets/rounded_text_input_field.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:html' as html;

import 'onboarding.dart';

const String kRandomTaskMenuButtonName = 'randomTask';

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

  bool isEditMode(TodoListItem todoItem) {
    bool sizeValidation =
        itemOnEditIndex > -1 && itemOnEditIndex < items.length;
    var index = items.indexOf(todoItem);
    bool indexValidation = index > -1;
    bool sameIndexValidation = itemOnEditIndex == index;
    return sizeValidation && indexValidation && sameIndexValidation;
  }

  int itemOnEditIndex = -1;

  // Add a variable to control the opacity of the FloatingActionButton
  double fabOpacity = fabOpacityOff;

  final FocusNode _todoLineFocusNode = FocusNode();

  //todo refactor and extract code to widgets

  bool isLoading = true;

  late RoundedTextInputField todoInputField = RoundedTextInputField(
    hintText: AppLocale.enterTodoTextPlaceholder.getString(context),
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

  void _initializeTabs() async {
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadingData = loadList();
    if (false) initAds();
    initializeInstallPrompt();
    // _initializeTabs will be called from didChangeDependencies
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocale.title.getString(context)),
        bottom: _tabController == null
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  ..._categories.map((String name) => Tab(text: name)).toList(),
                  Tab(icon: Tooltip(message: AppLocale.addCategoryTooltip.getString(context), child: const Icon(Icons.add))),
                ],
              ),
        actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == kInstallMenuButtonName) {
                      showInstallPrompt();
                      context.showSnackBar(AppLocale.appIsInstalled.getString(context));
                    }
                    if (value == kArchiveMenuButtonName) {
                      showArchivedTodos();
                    } else if (value == kDeleteAllMenuButtonName) {
                      deleteAll();
                    } else if (value == kLoginButtonMenu) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OnboardingScreen()));
                    } else if (value == kSettingsMenuButtonName) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()));
                    } else if (value == kRandomTaskMenuButtonName) {
                      _showRandomTask();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuItem<String>> popupMenuItems = [];
                    //Check if should show Login Button
                    if (isLoggedIn == false) {
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kLoginButtonMenu,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.supervised_user_circle,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8.0),
                            Text(AppLocale.login.getString(context)),
                          ],
                        ),
                      ));
                    }
                    //Check if should show Archive Button
                    if (items.any((item) => item.isArchived)) {
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kArchiveMenuButtonName,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.archive,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8.0),
                            Text(AppLocale.archive.getString(context)),
                          ],
                        ),
                      ));
                    }
                    //Check if should show Install App prompt button
                    if (isInstallable()) {
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kInstallMenuButtonName,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.install_mobile,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8.0),
                            Text(AppLocale.installApp.getString(context)),
                          ],
                        ),
                      ));
                    }
                    //Check if should show Delete Button
                    if (items.isNotEmpty) {
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kDeleteAllMenuButtonName,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              AppLocale.deleteAll.getString(context),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ));
                    }
                    popupMenuItems.add(PopupMenuItem<String>(
                      value: kSettingsMenuButtonName,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.settings_outlined,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8.0),
                          Text(AppLocale.settings.getString(context)),
                        ],
                      ),
                    ));
                    // Add Random Task button
                    popupMenuItems.add(PopupMenuItem<String>(
                      value: kRandomTaskMenuButtonName,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shuffle,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8.0),
                          Text(AppLocale.randomTaskMenuButton.getString(context)),
                        ],
                      ),
                    ));
                    return popupMenuItems;
                  },
                ),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _tabController == null || _categories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    // Children count should only be for actual categories, not the "+" tab
                    children: _categories.map((String categoryName) {
                      return FutureBuilder<List<TodoListItem>>(
                        future: _loadingData, // This future now correctly reloads all items
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          } else {
                            final allLoadedItems = snapshot.data ?? [];
                            items = allLoadedItems; // Keep the main 'items' list updated

                            List<TodoListItem> displayedItems;
                            if (categoryName == AppLocale.all.getString(context)) {
                              displayedItems = allLoadedItems.reversed
                                  .where((item) => !item.isArchived)
                                  .toList();
                            } else {
                              displayedItems = allLoadedItems.reversed
                                  .where((item) =>
                                      !item.isArchived &&
                                      item.category == categoryName)
                                  .toList();
                            }

                            return ListView.builder(
                              itemCount: displayedItems.length,
                              itemBuilder: (context, position) {
                                final TodoListItem currentTodo =
                                    displayedItems[position];
                                return getListTile(currentTodo);
                              },
                            );
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
                tooltip: AppLocale.deleteAllSubtitle.getString(context),
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
      DialogHelper.showAlertDialog(context, "Empty Todo", "Please write a Todo", // todo lang
          () {
        // Ok
        Navigator.of(context).pop(); // dismiss dialog
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
                                  getFormattedDate(todo.dateTime.toString()),
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
                                          itemOnEditIndex = -1;
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
    var isOnEditMode = isEditMode(currentTodo);
    var currentTodoEditInput = RoundedTextInputField(
      initialText: currentTodo.text,
      hintText: "Edit your ToDo here!",
      onChanged: (newValue) {
        setState(() {
          //todo update the current tile here
          var index = items.indexOf(currentTodo);
          // items[index].text = newValue;
          items[index].dateTime = DateTime.now();
          _updateList();
          // inputText = newValue;
        });
      },
      focusNode: FocusNode(),
      callback: () {
        print("Clicked enter from edit");
        _onAddItem();
      },
    );
    return InkWell(
      onLongPress: () {
        if (isEditMode(currentTodo)) {
          toggleEditMode(currentTodo); // Optionally exit edit mode
        } else {
          _showTodoContextMenu(currentTodo);
        }
      },
      onTap: () {
        if (isOnEditMode) {
          var updatedTodoText = currentTodoEditInput.getText();
          updateTile(currentTodo, updatedTodoText); // todo impl and debug
          toggleEditMode(currentTodo);
        } else {
          toggleCheckBox(currentTodo, !currentTodo.isChecked);
        }
      },
      child: SizedBox(
        child: ListTile(
          leading: isOnEditMode
              ? TextButton(
                  onPressed: () {
                    var updatedTodoText = currentTodoEditInput.getText();
                    updateTile(
                        currentTodo, updatedTodoText); // todo impl and debug
                    toggleEditMode(currentTodo);
                  },
                  child: const Icon(
                    Icons.save,
                    color: Colors.black12,
                  ))
              : Checkbox(
                  value: currentTodo.isChecked,
                  onChanged: (bool? value) {
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
          subtitle: isOnEditMode
              ? Container()
              : Text(
                  getFormattedDate(currentTodo.dateTime.toString()),
                  style: TextStyle(
                    decoration: currentTodo.isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
          trailing: isOnEditMode
              ? TextButton(
                  onPressed: () {
                    DialogHelper.showAlertDialog(context,
                        "Do you want to delete?", "This can't be undone", () {
                      Navigator.of(context).pop(); // dismiss dialog
                      setState(() {
                        items.remove(currentTodo);
                        _updateList();
                      });
                    }, () {
                      // Cancel
                      Navigator.of(context).pop(); // dismiss dialog
                    });
                  },
                  child: const Icon(
                    Icons.delete,
                    color: Colors.black12,
                  ))
              : null,
        ),
      ),
    );
  }

  void toggleCheckBox(TodoListItem currentTodo, bool? value) {
    setState(() {
      currentTodo.isChecked = value ?? false;
      _updateList();
    });
  }

  void toggleEditMode(TodoListItem currentTodo) {
    setState(() {
      if (itemOnEditIndex == -1) {
        var index = items.indexOf(currentTodo);
        itemOnEditIndex = index;
      } else {
        itemOnEditIndex = -1;
      }
    });
  }

  void updateTile(TodoListItem currentTodo, String todoText) {
    setState(() {
      var index = items.indexOf(currentTodo);
      var didChanged = false;
      if (todoText.isNotEmpty) {
        didChanged = currentTodo.text != todoText;
        currentTodo.text = todoText; // todo fix issues w updating the text
      }
      if (didChanged) {
        currentTodo.dateTime = DateTime.now();
      }
      items[index] = currentTodo;
      _updateList();
    });
  }

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
    final availableTasks = items
        .where((item) => !item.isArchived && !item.isChecked)
        .toList();

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

  void _promptForNewCategory({int? selectedIndexToRestore}) async {
    final TextEditingController categoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool categoryAddedSuccessfully = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button for explicit action
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
                        // Check against _customCategories for uniqueness, "All" is not a custom category.
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
                  Navigator.of(dialogContext).pop();
                },
              ),
              TextButton(
                child: Text(AppLocale.okButtonText.getString(dialogContext)),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newCategory = categoryController.text.trim();
                    setState(() {
                      _customCategories.add(newCategory);
                      EncryptedSharedPreferencesHelper.saveCategories(_customCategories); // No need to await if not critical path for UI

                      _categories = [AppLocale.all.getString(context), ..._customCategories];

                      final newCategoryIndexInCategories = _categories.length - 1; // Index of the newly added category tab

                      _tabController?.removeListener(_handleTabSelection);
                      _tabController?.dispose();
                      _tabController = TabController(
                        length: _categories.length + 1, // +1 for the "+" tab itself
                        vsync: this,
                        initialIndex: newCategoryIndexInCategories, // Select the newly added actual category tab
                      );
                      _tabController!.addListener(_handleTabSelection);
                      categoryAddedSuccessfully = true;
                    });
                    Navigator.of(dialogContext).pop(); // Close dialog on success
                  }
                },
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isPromptingForCategory = false;
      });
    }

    // If the dialog was dismissed without adding a category (e.g., pressed cancel or validation failed after trying)
    // and a selectedIndexToRestore is provided, ensure the tab selection is reverted.
    if (!categoryAddedSuccessfully && selectedIndexToRestore != null && _tabController != null) {
      // Only revert if the current index is still the "+" button's potential index
      // This check is important because if the user somehow managed to change tabs while dialog was open, we shouldn't interfere.
      // Also ensure the controller is not disposed before animating.
      if (_tabController!.index == _categories.length && mounted) { // `mounted` check for safety
        _tabController!.animateTo(selectedIndexToRestore);
      }
    }
  }

  void _showTodoContextMenu(TodoListItem todoItem) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(AppLocale.editMenuItem.getString(context)),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  toggleEditMode(todoItem);
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: Text(AppLocale.moveToCategoryMenuItem.getString(context)),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _promptMoveToCategory(todoItem);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(AppLocale.deleteMenuItem.getString(context), style: const TextStyle(color: Colors.red)),
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
     DialogHelper.showAlertDialog(
        context,
        AppLocale.doUwant2Delete.getString(context), // Assuming this key exists
        AppLocale.thisCantBeUndone.getString(context), // Assuming this key exists
        () {
      Navigator.of(context).pop(); // dismiss confirmation dialog
      setState(() {
        items.remove(todoItem);
        if (itemOnEditIndex >= items.length) { // Adjust if delete was last item
          itemOnEditIndex = -1;
        } else if (items.isNotEmpty && itemOnEditIndex != -1 && items[itemOnEditIndex] == todoItem) {
           // If the deleted item was the one being edited.
           itemOnEditIndex = -1;
        }
        _updateList();
      });
    }, () {
      // Cancel
      Navigator.of(context).pop(); // dismiss dialog
    });
  }

  void _promptMoveToCategory(TodoListItem todoItem) async {
    List<String> availableCategories = List.from(_customCategories);
    // String? currentItemCategory = todoItem.category; // Not strictly needed for display logic here

    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: Text(AppLocale.selectCategoryDialogTitle.getString(dialogContext)),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, null); // Represents "Uncategorized"
              },
              child: Text(AppLocale.uncategorizedCategory.getString(dialogContext)),
            ),
            ...availableCategories.map((category) {
              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(dialogContext, category);
                },
                child: Text(category),
              );
            }).toList(),
          ],
        );
      },
    ).then((selectedCategoryName) {
      if (selectedCategoryName != todoItem.category || (selectedCategoryName == null && todoItem.category != null) || (selectedCategoryName != null && todoItem.category == null) ) { // check if category actually changed
        bool categoryWasActuallySelected = true; // A bit of a misnomer, this means a choice was made, even if it's "Uncategorized"
        if(selectedCategoryName == null && todoItem.category == null) { // If chose uncategorized and it was already uncategorized
            categoryWasActuallySelected = false;
        }


        if (categoryWasActuallySelected) {
          setState(() {
            todoItem.category = selectedCategoryName;
            _updateList();
          });
          // Show feedback to the user
          final snackBar = SnackBar(
            content: Text(
              selectedCategoryName == null
                  ? AppLocale.itemUncategorizedSnackbar.getString(context)
                  : AppLocale.itemMovedSnackbar.getString(context).replaceAll('{categoryName}', selectedCategoryName),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    });
  }
}