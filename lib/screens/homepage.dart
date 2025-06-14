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
    // Dispose old controller if exists
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();

    _customCategories = await EncryptedSharedPreferencesHelper.loadCategories();
    setState(() {
      _categories = [
        AppLocale.all.getString(context), ..._customCategories
      ];
      _tabController = TabController(length: _categories.length, vsync: this);
      _tabController!.addListener(_handleTabSelection);
    });
  }

  void _handleTabSelection() {
    if (_tabController != null && _tabController!.indexIsChanging) {
      // Optional: Add logic here if something needs to happen on tab selection
      // beyond what TabBarView handles. For now, setState might be enough if
      // filtering logic depends on the selected tab index directly.
      setState(() {});
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
        bottom: _tabController == null || _categories.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _categories.map((String name) => Tab(text: name)).toList(),
              ),
        actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add new category', // TODO: Localize this
                  onPressed: _promptForNewCategory,
                ),
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
                    children: _categories.map((String categoryName) {
                      return FutureBuilder<List<TodoListItem>>(
                        future: _loadingData,
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
        toggleEditMode(currentTodo);
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

  void _promptForNewCategory() async {
    final TextEditingController categoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('New Category'), // TODO: Localize
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(hintText: "Category name"), // TODO: Localize
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Category name cannot be empty.'; // TODO: Localize
                      }
                      if (_categories.any((cat) => cat.toLowerCase() == value.trim().toLowerCase())) {
                        return 'Category already exists.'; // TODO: Localize
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
              child: Text(AppLocale.cancel.getString(context)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(AppLocale.ok.getString(context)),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newCategory = categoryController.text.trim();
                  setState(() {
                    _customCategories.add(newCategory);
                    EncryptedSharedPreferencesHelper.saveCategories(_customCategories);

                    _categories = [AppLocale.all.getString(context), ..._customCategories];

                    _tabController?.removeListener(_handleTabSelection);
                    _tabController?.dispose();
                    _tabController = TabController(
                      length: _categories.length,
                      vsync: this,
                      initialIndex: _categories.length - 1, // Select the new tab
                    );
                    _tabController!.addListener(_handleTabSelection);
                  });
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}