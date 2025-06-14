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

class _HomePageState extends State<HomePage> with PWAInstallerMixin {
  String inputText = "";
  bool enteredAtLeast1Todo = false;

  List<TodoListItem> items = [];
  late Future<List<TodoListItem>> _loadingData;

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
    // Load ad after build is complete
    Future.delayed(Duration.zero, () {
      myBanner?.load();
    });
  }

  @override
  void dispose() {
    super.dispose();
    myBanner?.dispose();
    _todoLineFocusNode.dispose(); // Dispose of the FocusNode
  }

  @override
  void initState() {
    _loadingData = loadList();
    if (false) initAds();
    initializeInstallPrompt();
    // Automatically show the install prompt if available
    if (isInstallable()) {
      showInstallPrompt();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocale.title.getString(context)),
        actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if(value == kInstallMenuButtonName) {
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
            child: FutureBuilder<List<TodoListItem>>(
              future: _loadingData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  items = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: items.where((item) => !item.isArchived).length,
                    itemBuilder: (context, position) {
                      final activeItems = items.reversed
                          .where((item) => !item.isArchived)
                          .toList();
                      final TodoListItem currentTodo = activeItems[position];

                      return getListTile(currentTodo);
                    },
                  );
                }
              },
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
                tooltip: AppLocale.add.getString(context),
                child: const Icon(Icons.add),
              ),
            )
          : Container(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _onAddItem() {
    if (inputText.isNotEmpty) {
      setState(() {
        items.add(TodoListItem(inputText.trim()));
        _updateList();

        inputText = "";
        todoInputField.clear();
        fabOpacity = fabOpacityOff;
      });
    } else {
      DialogHelper.showAlertDialog(context, AppLocale.emptyTodoTitle.getString(context), AppLocale.emptyTodoMessage.getString(context),
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
      hintText: AppLocale.editTodoHint.getString(context),
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
                        AppLocale.doUwant2Delete.getString(context), AppLocale.thisCantBeUndone.getString(context), () {
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
}