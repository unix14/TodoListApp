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
import 'package:firebase_auth/firebase_auth.dart'; // For current user UID
import 'package:flutter_example/models/shared_list_config.dart'; // For type hint
import 'package:flutter_example/widgets/share_list_dialog.dart'; // For ShareListDialog
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
const String kShareCategoryMenuButtonName = 'share_category';
const String kJoinSharedListMenuButtonName = 'join_shared_list';

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

  double fabOpacity = fabOpacityOff;
  final FocusNode _todoLineFocusNode = FocusNode();
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

  BannerAd? myBanner;
  AdWidget? adWidget;
  late AdListener listener;

  void initAds() {
    listener = AdListener(
      onAdLoaded: (Ad ad) {
        myBanner = ad as BannerAd;
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        ad.dispose();
        print('Ad failed to load: $error');
      },
      onAdOpened: (Ad ad) => print('Ad opened.'),
      onAdClosed: (Ad ad) => print('Ad closed.'),
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
    _initializeTabs();
    Future.delayed(Duration.zero, () {
      myBanner?.load();
    });
  }

  Future<void> _initializeTabs() async {
    int previousIndex = _tabController?.index ?? 0;
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    _tabController = null;
    _customCategories = await EncryptedSharedPreferencesHelper.loadCategories();
    List<String> newCategories = [
      AppLocale.all.getString(context),
      ..._customCategories
    ];
    if (previousIndex >= newCategories.length + 1) {
      previousIndex = 0;
    }
    if (previousIndex == newCategories.length) {
       previousIndex = 0;
    }
    if (previousIndex > newCategories.length) {
        previousIndex = 0;
    }
    if (newCategories.isEmpty) {
        previousIndex = 0;
    }
    TabController newTabController = TabController(
      length: newCategories.length + 1,
      vsync: this,
      initialIndex: previousIndex,
    );
    newTabController.addListener(_handleTabSelection);
    if (mounted) {
      setState(() {
        _categories = newCategories;
        _tabController = newTabController;
      });
    } else {
      newTabController.dispose();
    }
  }

  void _handleTabSelection() {
    if (_tabController == null) return;
    if (_isPromptingForCategory) return;
    if (_tabController!.index == _categories.length) {
      final previousIndex = _tabController!.previousIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tabController!.index == _categories.length) {
          _isPromptingForCategory = true;
          _promptForNewCategory(selectedIndexToRestore: previousIndex);
        }
      });
    } else {
       if (_tabController!.indexIsChanging) {
         setState(() {
         });
       }
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    myBanner?.dispose();
    _todoLineFocusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _loadingData = loadList();
    if (false) initAds();
    initializeInstallPrompt();
  }

  void _setEditingTodo(TodoListItem? todo) {
    setState(() {
      _editingTodo = todo;
      if (todo != null) {
        _textEditingController.text = todo.text;
      } else {
        _textEditingController.clear();
      }
    });
  }

  bool _isCurrentCategoryCustom() {
    if (_tabController == null || _categories.isEmpty) {
      return false;
    }
    if (_tabController!.index < 0 || _tabController!.index >= _categories.length) {
      return false;
    }
    return _categories[_tabController!.index] != AppLocale.all.getString(context);
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
                  onSelected: (value) async {
                    if (value == kInstallMenuButtonName) {
                      showInstallPrompt();
                      context.showSnackBar(AppLocale.appIsInstalled.getString(context));
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
                    } else if (value == kShareCategoryMenuButtonName) {
                      if (_isCurrentCategoryCustom()) {
                        final currentCategoryName = _categories[_tabController!.index];
                        _showShareDialog(currentCategoryName, currentCategoryName);
                      }
                    } else if (value == kJoinSharedListMenuButtonName) {
                        _promptToJoinSharedList();
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
                          AppLocale.deleteCategoryConfirmationTitle.getString(context),
                          AppLocale.deleteCategoryConfirmationMessage.getString(context).replaceAll('{categoryName}', currentCategoryName),
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
                              content: Text(AppLocale.categoryDeletedSnackbar.getString(context).replaceAll('{categoryName}', currentCategoryName)),
                            ));
                          },
                          () {
                            Navigator.of(context).pop();
                          },
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuItem<String>> popupMenuItems = [];
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
                    if (_isCurrentCategoryCustom()) {
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kRenameCategoryMenuButtonName,
                        child: Row(
                          children: [
                            const Icon(Icons.edit, color: Colors.blue),
                            const SizedBox(width: 8.0),
                            Text(AppLocale.renameCategoryMenuButton.getString(context)),
                          ],
                        ),
                      ));
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kShareCategoryMenuButtonName,
                        child: Row(
                          children: [
                            const Icon(Icons.share, color: Colors.blue),
                            const SizedBox(width: 8.0),
                            Text(AppLocale.shareCategoryButtonTooltip.getString(context)),
                          ],
                        ),
                      ));
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kDeleteCategoryMenuButtonName,
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red),
                            const SizedBox(width: 8.0),
                            Text(AppLocale.deleteCategoryMenuButton.getString(context), style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ));
                    }
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
                    if (FirebaseAuth.instance.currentUser != null) {
                        popupMenuItems.add(PopupMenuItem<String>(
                        value: kJoinSharedListMenuButtonName,
                        child: Row(
                          children: [
                            const Icon(Icons.group_add, color: Colors.blue),
                            const SizedBox(width: 8.0),
                            Text(AppLocale.simulateOpenLinkButton.getString(context)),
                          ],
                        ),
                      ));
                    }
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
                            items = allLoadedItems;
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
                            if (categoryName == AppLocale.all.getString(context) && displayedItems.isEmpty) {
                              final List<String> motivationalKeys = [
                                AppLocale.motivationalSentence1,
                                AppLocale.motivationalSentence2,
                                AppLocale.motivationalSentence3,
                                AppLocale.motivationalSentence4,
                                AppLocale.motivationalSentence5,
                              ];
                              final randomKey = motivationalKeys[Random().nextInt(motivationalKeys.length)];
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    randomKey.getString(context),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (displayedItems.isNotEmpty) {
                              String taskCountString;
                              if (displayedItems.length == 1) {
                                taskCountString = AppLocale.tasksCountSingular.getString(context);
                              } else {
                                taskCountString = AppLocale.tasksCount.getString(context).replaceAll('{count}', displayedItems.length.toString());
                              }
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Text(
                                      taskCountString,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13.0,
                                        color: Colors.blueGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: displayedItems.length,
                                      itemBuilder: (context, position) {
                                        final TodoListItem currentTodo = displayedItems[position];
                                        return getListTile(currentTodo);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return ListView.builder(
                                itemCount: 0,
                                itemBuilder: (context, position) => Container(),
                              );
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
                tooltip: AppLocale.deleteAllSubtitle.getString(context),
                child: const Icon(Icons.add),
              ),
            )
          : Container(),
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
        _updateList();
        inputText = "";
        todoInputField.clear();
        fabOpacity = fabOpacityOff;
      });
    } else {
      DialogHelper.showAlertDialog(
          context,
          AppLocale.emptyTodoDialogTitle.getString(context),
          AppLocale.emptyTodoDialogMessage.getString(context),
          () {
        Navigator.of(context).pop();
      }, null);
    }
  }

  void _updateList() async {
    var listAsStr = jsonEncode(items);
    await EncryptedSharedPreferencesHelper.setString(kAllListSavedPrefs, listAsStr);
    print("update list :" + listAsStr);
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
    HomeWidget.updateWidget(
      name: 'com.eyalya94.tools.todoLater.TodoWidgetProvider',
      iOSName: 'TodoWidgetProvider',
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                              });
                            },
                            child: SizedBox(
                              child: ListTile(
                                leading: Checkbox(
                                  value: todo.isChecked,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      todo.isChecked = !todo.isChecked;
                                      todo.dateTime = DateTime.now();
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
                                        setState(() {
                                          items.remove(todo);
                                          if (_editingTodo == todo) {
                                            _setEditingTodo(null);
                                          }
                                          _updateList();
                                        });
                                        Navigator.of(context).pop();
                                      }, () {
                                        Navigator.of(context).pop();
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
                    Navigator.of(context).pop();
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
    _updateList();
  }

  Future<List<TodoListItem>> _loadList() async {
    var listStr = await EncryptedSharedPreferencesHelper.getString(kAllListSavedPrefs) ?? "";
    print("load list :" + listStr);
    if (listStr.isNotEmpty) {
      List<dynamic> decodedList = jsonDecode(listStr);
      List<TodoListItem> sharedPrefsTodoList = decodedList.isNotEmpty ?
      decodedList.map((item) => TodoListItem.fromJson(item)).toList() : [];
      if (isLoggedIn && currentUser != null) {
        if (myCurrentUser == null) {
          myCurrentUser = await FirebaseRepoInteractor.instance
              .getUserData(currentUser!.uid);
          print("Loading first time the data from the DB");
        }
        print("the result for ${currentUser!.uid} is ${myCurrentUser?.todoListItems?.length ?? -1}");
        if (myCurrentUser != null && myCurrentUser?.todoListItems != null) {
          print("Loading from the DB");
          if (sharedPrefsTodoList.isNotEmpty) {
            var didMerged = false;
            for (var item in sharedPrefsTodoList) {
              if (!myCurrentUser!.todoListItems!.contains(item) &&
                  !myCurrentUser!.todoListItems!.any((element) =>
                      element.text == item.text &&
                      element.isArchived == item.isArchived)) {
                myCurrentUser!.todoListItems!.add(item);
                didMerged = true;
              }
            }
            if (didMerged) {
              var didSuccess = await FirebaseRepoInteractor.instance
                  .updateUserData(myCurrentUser!);
              if (didSuccess == true) {
                print("success save to DB");
              } else {
                print("failed save to DB");
              }
              await EncryptedSharedPreferencesHelper.setString(
                  kAllListSavedPrefs, jsonEncode(myCurrentUser!.todoListItems));
            }
          }
          return myCurrentUser!.todoListItems!;
        }
      }
      return sharedPrefsTodoList;
    } else {
      if (myCurrentUser == null && currentUser != null) {
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
    return InkWell(
      onLongPress: () {
        if (_editingTodo == currentTodo) {
          _saveTodo(currentTodo, _textEditingController.text);
        } else {
          if (_editingTodo != null) {
            _saveTodo(_editingTodo!, _textEditingController.text);
          }
          _showTodoContextMenu(currentTodo);
        }
      },
      onTap: () {
        if (isEditMode(currentTodo)) {
        } else if (_editingTodo != null) {
          _saveTodo(_editingTodo!, _textEditingController.text);
          toggleCheckBox(currentTodo, !currentTodo.isChecked);
        } else {
          toggleCheckBox(currentTodo, !currentTodo.isChecked);
        }
      },
      child: SizedBox(
        child: isEditMode(currentTodo)
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
                trailing: null,
                subtitle: null,
              )
            : ListTile(
                leading: Checkbox(
                  value: currentTodo.isChecked,
                  onChanged: (bool? value) {
                     if (_editingTodo != null && _editingTodo != currentTodo) {
                        _saveTodo(_editingTodo!, _textEditingController.text);
                    } else if (_editingTodo == currentTodo) {
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
      _setEditingTodo(null);
      return;
    }
    setState(() {
      if (todo.text != newText.trim()) {
        todo.text = newText.trim();
        todo.dateTime = DateTime.now();
      }
      _updateList();
    });
    _setEditingTodo(null);
  }

  void toggleCheckBox(TodoListItem currentTodo, bool? value) {
    if (isEditMode(currentTodo)) return;
    if (_editingTodo != null && _editingTodo != currentTodo) {
       _saveTodo(_editingTodo!, _textEditingController.text);
    }
    _setEditingTodo(null);
    setState(() {
      currentTodo.isChecked = value ?? false;
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
      Navigator.of(context).pop();
    });
  }

  void _showRandomTask() {
    String currentCategoryName = AppLocale.all.getString(context);
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
          Navigator.of(context).pop();
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
          Navigator.of(context).pop();
        },
        null,
      );
    }
  }

  Future<String?> _promptForNewCategory({int? selectedIndexToRestore}) async {
    final TextEditingController categoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? newCategoryName;
    try {
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
                  Navigator.of(dialogContext).pop(null);
                },
              ),
              TextButton(
                child: Text(AppLocale.okButtonText.getString(dialogContext)),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newCategory = categoryController.text.trim();
                    Navigator.of(dialogContext).pop(newCategory);
                  }
                },
              ),
            ],
          );
        },
      );
      if (newCategoryName != null) {
        setState(() {
          _customCategories.add(newCategoryName!);
          EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
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
            length: _categories.length + 1,
            vsync: this,
            initialIndex: newCategoryIndexInCategories,
          );
          _tabController!.addListener(_handleTabSelection);
        });
      }
    } finally {
      setState(() {
        _isPromptingForCategory = false;
      });
    }
    if (newCategoryName == null && selectedIndexToRestore != null && _tabController != null) {
      if (_tabController!.index == _categories.length && mounted) {
        _tabController!.animateTo(selectedIndexToRestore);
      }
    }
    return newCategoryName;
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
                  _setEditingTodo(todoItem);
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
        AppLocale.doUwant2Delete.getString(context),
        AppLocale.thisCantBeUndone.getString(context),
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
    List<String> availableCategories = List.from(_customCategories);
    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: Text(AppLocale.selectCategoryDialogTitle.getString(dialogContext)),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, null);
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
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, kAddNewCategoryOption);
              },
              child: Text(AppLocale.addNewCategoryMenuItem.getString(dialogContext)),
            ),
          ],
        );
      },
    ).then((selectedCategoryNameOrAction) {
      if (selectedCategoryNameOrAction == kAddNewCategoryOption) {
        _promptForNewCategory().then((newlyCreatedCategoryName) {
          if (newlyCreatedCategoryName != null && newlyCreatedCategoryName.isNotEmpty) {
            setState(() {
              todoItem.category = newlyCreatedCategoryName;
              _updateList();
            });
            _initializeTabs();
            final snackBar = SnackBar(
              content: Text(
                AppLocale.itemMovedSnackbar.getString(context).replaceAll('{categoryName}', newlyCreatedCategoryName),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        });
      } else {
        final selectedCategoryName = selectedCategoryNameOrAction as String?;
        if (selectedCategoryName != todoItem.category || (selectedCategoryName == null && todoItem.category != null) || (selectedCategoryName != null && todoItem.category == null) ) {
          bool categoryWasActuallySelected = true;
          if(selectedCategoryName == null && todoItem.category == null) {
              categoryWasActuallySelected = false;
          }
          if (categoryWasActuallySelected) {
            setState(() {
              todoItem.category = selectedCategoryName;
              _updateList();
            });
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
      }
    });
  }

  Future<String?> _promptRenameCategory(String oldCategoryName) async {
    final TextEditingController categoryController = TextEditingController(text: oldCategoryName);
    final formKey = GlobalKey<FormState>();
    String? newCategoryName;
    try {
      newCategoryName = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(AppLocale.renameCategoryDialogTitle.getString(dialogContext)),
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
                        final newNameTrimmed = value.trim();
                        if (newNameTrimmed.toLowerCase() == AppLocale.all.getString(dialogContext).toLowerCase()) {
                          return AppLocale.categoryNameExistsError.getString(dialogContext);
                        }
                        if (newNameTrimmed.toLowerCase() != oldCategoryName.toLowerCase() &&
                            _customCategories.any((cat) => cat.toLowerCase() == newNameTrimmed.toLowerCase())) {
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
                  Navigator.of(dialogContext).pop(null);
                },
              ),
              TextButton(
                child: Text(AppLocale.renameButtonText.getString(dialogContext)),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(dialogContext).pop(categoryController.text.trim());
                  }
                },
              ),
            ],
          );
        },
      );
      if (newCategoryName != null && newCategoryName != oldCategoryName) {
        setState(() {
          final oldNameIndex = _customCategories.indexWhere((cat) => cat.toLowerCase() == oldCategoryName.toLowerCase());
          if (oldNameIndex != -1) {
            _customCategories[oldNameIndex] = newCategoryName!;
          }
          for (var item in items) {
            if (item.category == oldCategoryName) {
              item.category = newCategoryName;
            }
          }
          EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
          HomeWidget.updateWidget(
            name: 'com.eyalya94.tools.todoLater.TodoWidgetProvider',
            iOSName: 'TodoWidgetProvider',
          );
          print('[HomeWidget] Sent update request to widget provider after renaming category.');
          _updateList();
          _initializeTabs();
          final snackBar = SnackBar(
            content: Text(
              AppLocale.categoryRenamedSnackbar.getString(context)
                  .replaceAll('{oldName}', oldCategoryName)
                  .replaceAll('{newName}', newCategoryName!),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      } else if (newCategoryName != null && newCategoryName == oldCategoryName) {
      }
      return newCategoryName;
    } catch (e) {
      print("Error in _promptRenameCategory: $e");
      return null;
    }
  }

  void _showShareDialog(String categoryName, String categoryId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ShareListDialog(categoryName: categoryName, categoryId: categoryId);
      },
    );
  }

  Future<void> _promptToJoinSharedList() async {
    final TextEditingController linkPathController = TextEditingController();
    final GlobalKey<FormFieldState<String>> formFieldKey = GlobalKey();

    // Actual deep link handling would typically involve:
    // 1. Configuring your app to recognize custom URL schemes or universal links.
    // 2. Using a routing package to listen for incoming links.
    // 3. When a link is received, parse the shortLinkPath from it.
    // 4. Call the join logic similar to what's below.

    final String? enteredPath = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocale.simulateOpenLinkButton.getString(dialogContext)), // New Locale: "Join a Shared List"
          content: TextFormField(
            key: formFieldKey,
            controller: linkPathController,
            decoration: InputDecoration(hintText: AppLocale.enterLinkPathHint.getString(dialogContext)), // New Locale: "Enter shared link path"
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocale.linkPathInvalid.getString(dialogContext); // New Locale: "Link path cannot be empty"
              }
              return null;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocale.cancelButtonText.getString(dialogContext)),
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
            ),
            TextButton(
              child: Text(AppLocale.joinButtonText.getString(dialogContext)), // New Locale: "Join"
              onPressed: () {
                if (formFieldKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(linkPathController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    if (enteredPath != null && enteredPath.isNotEmpty) {
      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserUid == null) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.loginToJoinPrompt.getString(context))), // New Locale
          );
        }
        return;
      }

      try {
        // Optionally, show a loading indicator here
        final SharedListConfig? joinedConfig = await FirebaseRepoInteractor.instance.joinSharedList(enteredPath, currentUserUid);

        if (mounted && joinedConfig != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.joinListSuccess.getString(context).replaceAll('{listName}', joinedConfig.originalCategoryName))), // New Locale
          );
          // Refresh categories to include the newly joined list
          await _initializeTabs();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.joinListError.getString(context))), // New Locale
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${AppLocale.joinListError.getString(context)}: $e")),
          );
        }
      }
    }
  }
}

// Define a constant for the "Add New Category" option to avoid magic strings
const String kAddNewCategoryOption = 'add_new_category_option_val'; // Made it more unique