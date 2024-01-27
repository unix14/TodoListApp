import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/stub_data.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/DialogHelper.dart';
import 'common/date_extensions.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //todo add rtl support??
      // home: Column(
      //   children: [
      home: const MyHomePage(title: 'Todo List'),
      //     Container(
      //       alignment: Alignment.bottomCenter,
      //       child: adWidget,
      //       width: myBanner?.size.width.toDouble() ?? 0,
      //       height: myBanner?.size.height.toDouble() ?? 0,
      //     )
      //   ],
      // ),
    );
  }
  //
  //

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String inputText = "";

  List<TodoListItem> items = [];
  late Future<List<TodoListItem>> _loadingData;
  bool isEditMode = false;


  //todo refactor and extract code to widgets

  bool isLoading = true;
  final _controller = TextEditingController();


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
      adUnitId: kDebugMode ? "ca-app-pub-3940256099942544/6300978111" : "ca-app-pub-7481638286003806/6665802500",
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener,
    );
    myBanner?.load();
    if(myBanner != null) {
      adWidget = AdWidget(ad:myBanner!);
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
  }

  @override
  void initState() {
    _loadingData = loadList();
    initAds();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: items.isNotEmpty ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == kArchiveMenuButtonName) {
                      showArchivedTodos();
                    } else if (value == kDeleteAllMenuButtonName) {
                      deleteAll();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuItem<String>> popupMenuItems = [];
                    //Check if should show Archive Button
                    if (items.any((item) => item.isArchived)) {
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: 'archive',
                        child: Row(
                          children: const [
                            Icon(Icons.archive,
                              color: Colors.blue,),
                            SizedBox(width: 8.0),
                            Text('Archive'),
                          ],
                        ),
                      ));
                    }
                    //Check if should show Delete Button
                    if (items.isNotEmpty) {
                      popupMenuItems.add(PopupMenuItem<String>(
                        value: kDeleteAllMenuButtonName,
                        child: Row(
                          children: const [
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
                      final activeItems = items
                          .reversed
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
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (newValue) {
                      setState(() {
                        inputText = newValue;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 2.0,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                  ),
                ),
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
      floatingActionButton: (inputText.isNotEmpty) ? FloatingActionButton(
        onPressed: () {
          if (inputText.isNotEmpty) {
            setState(() {
              items.add(TodoListItem(inputText.trim()));
              _updateList();

              inputText = "";
              _controller.clear();
            });
          } else {
            DialogHelper.showAlertDialog(
                context, "Empty Todo", "Please write a Todo", null);
          }
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ) : Container(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _updateList() async {
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    //convert to JSON
    var listAsStr = jsonEncode(items);
    prefs.setString(kAllListSavedPrefs, listAsStr);
    print("update list :" + listAsStr);
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
                    const Text("Todos are added to the archive after 24 hours since they're checked as done."),
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
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    var listStr = prefs.getString(kAllListSavedPrefs) ?? "";
    print("load list :" + listStr);

    if (listStr.isNotEmpty) {
      List<dynamic> decodedList = jsonDecode(listStr);
      if (decodedList.isNotEmpty) {
        List<TodoListItem> todoList =
            decodedList.map((item) => TodoListItem.fromJson(item)).toList();
        return todoList;
      } else {
        return [];
      }
    } else {
      return StubData.getInitialTodoList();
    }
  }

  Widget getListTile(TodoListItem currentTodo) {
    return InkWell(
      onLongPress: () {
        setState(() {
          isEditMode = !isEditMode;
        });
      },
      onTap: () {
        toggleCheckBox(currentTodo, !currentTodo.isChecked);
      },
      child: SizedBox(
        child: ListTile(
          leading: Checkbox(
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
          subtitle: Text(
            getFormattedDate(currentTodo.dateTime.toString()),
            style: TextStyle(
              decoration: currentTodo.isChecked
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          trailing: isEditMode ? TextButton(
              onPressed: () {
                DialogHelper.showAlertDialog(
                    context, "Do you want to delete?", "This can't be undone",
                    () {
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
              )) : null,
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
