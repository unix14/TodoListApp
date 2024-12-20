import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_example/common/DialogHelper.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/date_extensions.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/common/stub_data.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/user.dart' as MyUser;
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/widgets/rounded_text_input_field.dart';
import 'package:flutter_example/widgets/rounded_text_input_field.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String inputText = "";

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
  double fabOpacity = 0.0;

  final FocusNode _todoLineFocusNode = FocusNode();

  //todo refactor and extract code to widgets

  bool isLoading = true;
  late RoundedTextInputField todoInputField = RoundedTextInputField(
    hintText: "Enter a Todo here..",
    onChanged: (newValue) {
      setState(() {
        inputText = newValue;
        fabOpacity = newValue.isNotEmpty ? 1 : 0;
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
      adUnitId: kDebugMode ? kAdUnitIdDebug : kAdUnitIdProd ,
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
    if (false) 
      initAds();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: (isLoggedIn == false ||
                items.isNotEmpty ||
                items.where((item) => item.isArchived).toList().isNotEmpty)
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == kArchiveMenuButtonName) {
                      showArchivedTodos();
                    } else if (value == kDeleteAllMenuButtonName) {
                      deleteAll();
                    } else if (value == kLoginButtonMenu) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OnboardingScreen()));
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuItem<String>> popupMenuItems = [];
                    //Check if should show Login Button
                    if (isLoggedIn == false) {
                      popupMenuItems.add(const PopupMenuItem<String>(
                        value: 'login',
                        child: Row(
                          children: [
                            Icon(
                              Icons.supervised_user_circle,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8.0),
                            Text('Login'),
                          ],
                        ),
                      ));
                    }
                    //Check if should show Archive Button
                    if (items.any((item) => item.isArchived)) {
                      popupMenuItems.add(const PopupMenuItem<String>(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              Icons.archive,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8.0),
                            Text('Archive'),
                          ],
                        ),
                      ));
                    }
                    //Check if should show Delete Button
                    if (items.isNotEmpty) {
                      popupMenuItems.add(const PopupMenuItem<String>(
                        value: kDeleteAllMenuButtonName,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_forever,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8.0),
                            Text('Delete All'),
                          ],
                        ),
                      ));
                    }
                    //Check if should show any buttons
                    if (items.isNotEmpty) {
                      return popupMenuItems;
                    } else {
                      return [];
                    }
                  },
                ),
              ]
            : [],
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
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                todoInputField,
                SizedBox(
                  height: 69.0,
                  width: inputText.isNotEmpty ? 80 : 10,
                  child: Container(),
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (inputText.isNotEmpty)
          ? FloatingActionButton(
              onPressed: () {
                _onAddItem();
              },
              tooltip: 'Add',
              child: const Icon(Icons.add),
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
      });
    } else {
      DialogHelper.showAlertDialog(
          context, "Empty Todo", "Please write a Todo", null);
    }
  }

  void _updateList() async {
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    //convert to JSON
    var listAsStr = jsonEncode(items);
    prefs.setString(kAllListSavedPrefs, listAsStr);
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
              title: const Text('Archived Todos'),
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
                                          "Do you want to delete?",
                                          "This can't be undone", () {
                                        // dismiss dialog
                                        setState(() {
                                          items.remove(todo);
                                          _updateList();
                                        });
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
                    const Text(
                        "Todos are added to the archive after 24 hours since they're checked as done."),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    setState(() {});
                  },
                  child: const Text('Close'),
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
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    var listStr = prefs.getString(kAllListSavedPrefs) ?? "";
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
        if (myCurrentUser != null &&
            myCurrentUser?.todoListItems != null) {
          print("Loading from the DB");

          if(sharedPrefsTodoList.isNotEmpty) {
            // Merge the two lists
            for (var item in sharedPrefsTodoList) {
              // check by parameters
              if (!myCurrentUser!.todoListItems!.contains(item) &&
                  !myCurrentUser!.todoListItems!.any((element) => element.text == item.text && element.isArchived == item.isArchived)) {
                myCurrentUser!.todoListItems!.add(item);
              }
            }

            // update firebase
            var didSuccess = await FirebaseRepoInteractor.instance.updateUserData(myCurrentUser!);
            if (didSuccess == true) {
              print("success save to DB");
            } else {
              print("failed save to DB");
            }
          }

          return myCurrentUser!.todoListItems!;
        }
      }
      return sharedPrefsTodoList;
    } else {
      return StubData.getInitialTodoList();
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
      if (todoText.isNotEmpty) {
        currentTodo.text = todoText;
      }
      currentTodo.dateTime = DateTime.now();
      items[index] = currentTodo;
      _updateList();
    });
  }

  void deleteAll() {
    DialogHelper.showAlertDialog(context, "Are you sure?",
        "Deleting all Todos will result in an empty list and an empty archive list. Do you really want to delete everything?",
        () {
      setState(() {
        items.clear();
        _updateList();
        Navigator.of(context).pop();
      });
    });
  }
}
