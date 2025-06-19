import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_example/common/DialogHelper.dart';
import 'package:flutter_example/common/common_styles.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/managers/app_initializer.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/models/shared_list_config.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/user.dart' as AppUser;
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/widgets/share_list_dialog.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:home_widget/home_widget.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // Ads commented out for now
import 'package:uuid/uuid.dart';

// Menu item constants
const String _kMenuSettings = 'settings';
const String _kMenuArchived = 'archived';
const String _kMenuJoinList = 'join_list';
const String _kMenuShareCategory = 'share_category'; // Dynamic, uses categoryId
const String _kMenuManageShare = 'manage_share';   // Dynamic, uses categoryId (which is sharedListId here)
const String _kMenuRenameCategory = 'rename_category'; // Dynamic, uses categoryId
const String _kMenuDeleteCategory = 'delete_category'; // Dynamic, uses categoryId


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

// Represents data for each tab (personal or shared)
class _TabData {
  final String id; // For personal: category name. For shared: SharedListConfig.id
  final String name; // Display name for the tab
  final bool isShared;
  final SharedListConfig? config; // Null for personal tabs

  _TabData({required this.id, required this.name, this.isShared = false, this.config});
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _todoController = TextEditingController();
  final FocusNode _todoFocusNode = FocusNode();
  TabController? _tabController;
  List<_TabData> _tabs = [];
  AppUser.User? _currentUser;
  StreamSubscription? _userChangesSubscription;
  StreamSubscription? _sharedListSubscription;
  Map<String, StreamSubscription?> _sharedListTodoSubscriptions = {};
  Map<String, List<TodoListItem>> _sharedListTodos = {};

  // BannerAd? _bannerAd; // Ads commented out
  // bool _isBannerAdLoaded = false; // Ads commented out

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndInitializeTabs();
    _userChangesSubscription = fb_auth.FirebaseAuth.instance.userChanges().listen((fb_auth.User? firebaseUser) {
      if (firebaseUser == null) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/onboarding');
      } else {
        _loadCurrentUserAndInitializeTabs(firebaseUser.uid);
      }
    });
    // _loadBannerAd(); // Ads commented out
    HomeWidget.widgetClicked.listen((Uri? uri) => _handleWidgetClick(uri));
    _updateWidget();
  }

  void _handleWidgetClick(Uri? uri) {
    if (uri?.host == 'widgetclick') {
        print('Widget clicked, potentially focus on input field.');
        // You might want to navigate to a specific tab or ensure the input field is visible
        if (_todoFocusNode.canRequestFocus) {
          _todoFocusNode.requestFocus();
        }
    }
  }

  Future<void> _updateWidget() async {
    // For simplicity, sending the current "All" category tasks count.
    // This should be expanded to allow user to choose category for widget or show summary.
    int taskCount = _currentUser?.todosByCategories['All']?.where((t) => !t.isDone).length ?? 0;
    await HomeWidget.saveWidgetData<String>('headline_text', AppLocale.tasksCount.getString(context).replaceAll('{count}', taskCount.toString()));
    await HomeWidget.updateWidget(name: 'TodoWidgetProvider', iOSName: 'TodoWidget');
    print("Widget data updated with task count: $taskCount");
  }


  // void _loadBannerAd() { // Ads commented out
  //   _bannerAd = BannerAd(
  //     adUnitId: Globals.bannerAdUnitId,
  //     request: const AdRequest(),
  //     size: AdSize.banner,
  //     listener: BannerAdListener(
  //       onAdLoaded: (_) => setState(() => _isBannerAdLoaded = true),
  //       onAdFailedToLoad: (ad, err) {
  //         print('Failed to load a banner ad: ${err.message}');
  //         ad.dispose();
  //       },
  //     ),
  //   );
  //   _bannerAd?.load();
  // }

  Future<void> _loadCurrentUserAndInitializeTabs([String? userId]) async {
    final uid = userId ?? fb_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }
    _currentUser = await FirebaseRepoInteractor.I.getUserData(uid);
    if (mounted) {
      setState(() {
        _initializeTabs();
      });
       _updateWidget(); // Update widget after loading user data
    }
  }

  void _initializeTabs() {
    _tabs.clear();
    _sharedListTodoSubscriptions.forEach((_, sub) => sub?.cancel());
    _sharedListTodoSubscriptions.clear();
    _sharedListTodos.clear();

    // Add personal categories as tabs
    _currentUser?.todosByCategories.keys.forEach((categoryName) {
      _tabs.add(_TabData(id: categoryName, name: categoryName));
    });
    if (_tabs.isEmpty) { // Ensure "All" tab always exists for personal tasks
        _tabs.add(_TabData(id: 'All', name: AppLocale.all.getString(context)));
        if (_currentUser != null && !_currentUser!.todosByCategories.containsKey('All')) {
            _currentUser!.todosByCategories['All'] = [];
        }
    }


    // Add shared lists as tabs
    _currentUser?.sharedListsConfigs.forEach((config) {
      _tabs.add(_TabData(id: config.id, name: "👥 ${config.listNameInSharedCollection}", isShared: true, config: config));
      _listenToSharedListTodos(config.id);
    });

    // Dispose old TabController if exists
    _tabController?.dispose();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        // Optional: Add logic when tab changes, e.g., clear text field
        // _todoController.clear();
      }
      setState(() {}); // Rebuild to update FAB or other UI elements based on tab
    });

    // If current user is null after all this (e.g. error), redirect.
    if (_currentUser == null && mounted) {
         Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  void _listenToSharedListTodos(String sharedListId) {
    _sharedListTodoSubscriptions[sharedListId]?.cancel(); // Cancel previous subscription if any
    _sharedListTodoSubscriptions[sharedListId] =
      FirebaseRepoInteractor.I.getTodosStreamForSharedList(sharedListId).listen((todos) {
        if (mounted) {
          setState(() {
            _sharedListTodos[sharedListId] = todos;
          });
        }
      }, onError: (error) {
        print("Error listening to shared list $sharedListId: $error");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.errorLoadingList.getString(context).replaceAll('{errorDetails}', error.toString()))));
        }
      });
  }


  @override
  void dispose() {
    _todoController.dispose();
    _todoFocusNode.dispose();
    _tabController?.dispose();
    _userChangesSubscription?.cancel();
    _sharedListSubscription?.cancel();
    _sharedListTodoSubscriptions.forEach((_, sub) => sub?.cancel());
    // _bannerAd?.dispose(); // Ads commented out
    super.dispose();
  }

  void _addOrUpdateTodo({TodoListItem? existingTodo, String? newText}) {
    if (_currentUser == null || _tabs.isEmpty) return;
    final currentTab = _tabs[_tabController!.index];
    final String text = newText ?? _todoController.text.trim();

    if (text.isEmpty) {
      DialogHelper.showAlertDialog(
          context: context,
          title: AppLocale.emptyTodoDialogTitle.getString(context),
          content: AppLocale.emptyTodoDialogMessage.getString(context),
          confirmButtonText: AppLocale.okButtonText.getString(context),
          onConfirm: () => Navigator.of(context, rootNavigator: true).pop()
      );
      return;
    }

    if (currentTab.isShared) {
      if (existingTodo == null) { // Add new
        final newSharedTodo = TodoListItem(id: Uuid().v4(), text: text, createdDate: DateTime.now(), category: currentTab.id);
        FirebaseRepoInteractor.I.addTodoToSharedList(currentTab.id, newSharedTodo);
      } else { // Update existing
        existingTodo.text = text;
        FirebaseRepoInteractor.I.updateTodoInSharedList(currentTab.id, existingTodo);
      }
    } else { // Personal todo
      final List<TodoListItem> categoryTodos = _currentUser!.todosByCategories[currentTab.id] ?? [];
      if (existingTodo == null) { // Add new
        final newPersonalTodo = TodoListItem(id: Uuid().v4(), text: text, createdDate: DateTime.now(), category: currentTab.id);
        categoryTodos.add(newPersonalTodo);
      } else { // Update existing
        final index = categoryTodos.indexWhere((t) => t.id == existingTodo.id);
        if (index != -1) {
          categoryTodos[index].text = text;
        }
      }
      _currentUser!.todosByCategories[currentTab.id] = categoryTodos;
      FirebaseRepoInteractor.I.saveUser(_currentUser!);
    }
    if (mounted) setState(() => _todoController.clear());
    _updateWidget();
  }

  void _toggleTodoStatus(TodoListItem todo) {
    if (_currentUser == null || _tabs.isEmpty) return;
    final currentTab = _tabs[_tabController!.index];

    todo.isDone = !todo.isDone;
    todo.lastUpdatedDate = DateTime.now();

    if (currentTab.isShared) {
      FirebaseRepoInteractor.I.updateTodoInSharedList(currentTab.id, todo);
    } else {
      final categoryTodos = _currentUser!.todosByCategories[currentTab.id];
      if (categoryTodos != null) {
        final index = categoryTodos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          categoryTodos[index] = todo;
          FirebaseRepoInteractor.I.saveUser(_currentUser!);
        }
      }
    }
     if (mounted) setState(() {});
     _updateWidget();
  }

  void _deleteTodo(TodoListItem todo) async {
    if (_currentUser == null || _tabs.isEmpty) return;
    final currentTab = _tabs[_tabController!.index];

    bool? confirmed = await DialogHelper.showAlertDialog(
      context: context,
      title: AppLocale.deleteMenuItem.getString(context),
      content: AppLocale.doUwant2Delete.getString(context),
      confirmButtonText: AppLocale.okButtonText.getString(context),
      cancelButtonText: AppLocale.cancelButtonText.getString(context),
    );

    if (confirmed == true) {
      if (currentTab.isShared) {
        FirebaseRepoInteractor.I.deleteTodoFromSharedList(currentTab.id, todo.id!);
      } else {
        final categoryTodos = _currentUser!.todosByCategories[currentTab.id];
        if (categoryTodos != null) {
          categoryTodos.removeWhere((t) => t.id == todo.id);
          FirebaseRepoInteractor.I.saveUser(_currentUser!);
        }
      }
      if (mounted) setState(() {});
      _updateWidget();
    }
  }

  void _editTodo(TodoListItem todo) {
    _todoController.text = todo.text;
    _todoFocusNode.requestFocus();
    // Temporarily remove the todo, it will be re-added/updated via _addOrUpdateTodo
    if (_currentUser == null || _tabs.isEmpty) return;
    final currentTab = _tabs[_tabController!.index];
    if (currentTab.isShared) {
      // For shared lists, we don't remove locally before edit to avoid UI flicker.
      // The update will come through the stream.
      // We pass existingTodo to _addOrUpdateTodo.
       DialogHelper.showTextInputDialog(
        context,
        title: AppLocale.editMenuItem.getString(context),
        initialValue: todo.text,
        hintText: AppLocale.editTaskHintText.getString(context),
        confirmButtonText: AppLocale.okButtonText.getString(context),
        cancelButtonText: AppLocale.cancelButtonText.getString(context),
        onConfirm: (newText) {
          _addOrUpdateTodo(existingTodo: todo, newText: newText);
        },
      );
    } else {
      // For personal lists, this approach is fine.
      final categoryTodos = _currentUser!.todosByCategories[currentTab.id];
      if (categoryTodos != null) {
         DialogHelper.showTextInputDialog(
            context,
            title: AppLocale.editMenuItem.getString(context),
            initialValue: todo.text,
            hintText: AppLocale.editTaskHintText.getString(context),
            confirmButtonText: AppLocale.okButtonText.getString(context),
            cancelButtonText: AppLocale.cancelButtonText.getString(context),
            onConfirm: (newText) {
              // No need to remove then add, just update directly
              _addOrUpdateTodo(existingTodo: todo, newText: newText);
            },
          );
      }
    }
  }

  void _addCategory() {
    DialogHelper.showTextInputDialog(
      context,
      title: AppLocale.addCategoryDialogTitle.getString(context),
      hintText: AppLocale.categoryNameHintText.getString(context),
      confirmButtonText: AppLocale.okButtonText.getString(context),
      cancelButtonText: AppLocale.cancelButtonText.getString(context),
      onConfirm: (categoryName) {
        if (categoryName.isNotEmpty) {
          if (_currentUser!.todosByCategories.containsKey(categoryName)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.categoryNameExistsError.getString(context))));
          } else {
            if (mounted) {
              setState(() {
                _currentUser!.todosByCategories[categoryName] = [];
                FirebaseRepoInteractor.I.saveUser(_currentUser!);
                _initializeTabs(); // Re-initialize to add new tab
                _tabController!.animateTo(_tabs.length - 1); // Go to new tab
              });
            }
          }
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.categoryNameEmptyError.getString(context))));
        }
      },
    );
  }

  void _renameCategory(String oldCategoryName) {
    DialogHelper.showTextInputDialog(
      context,
      title: AppLocale.renameCategoryDialogTitle.getString(context),
      initialValue: oldCategoryName,
      hintText: AppLocale.categoryNameHintText.getString(context),
      confirmButtonText: AppLocale.renameButtonText.getString(context),
      cancelButtonText: AppLocale.cancelButtonText.getString(context),
      onConfirm: (newName) {
        if (newName.isNotEmpty && newName != oldCategoryName) {
          if (_currentUser!.todosByCategories.containsKey(newName)) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.categoryNameExistsError.getString(context))));
          } else {
            if (mounted) {
              setState(() {
                final todos = _currentUser!.todosByCategories.remove(oldCategoryName);
                _currentUser!.todosByCategories[newName] = todos ?? [];
                // Update category for each todo item
                _currentUser!.todosByCategories[newName]?.forEach((todo) => todo.category = newName);
                FirebaseRepoInteractor.I.saveUser(_currentUser!);
                _initializeTabs(); // Re-initialize tabs
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.categoryRenamedSnackbar.getString(context).replaceAll('{oldName}', oldCategoryName).replaceAll('{newName}', newName))));
              });
            }
          }
        } else if (newName.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.categoryNameEmptyError.getString(context))));
        }
      },
    );
  }

  void _deleteCategory(String categoryName) async {
    if (categoryName == "All") return; // Cannot delete "All"

    bool? confirmed = await DialogHelper.showAlertDialog(
      context: context,
      title: AppLocale.deleteCategoryConfirmationTitle.getString(context),
      content: AppLocale.deleteCategoryConfirmationMessage.getString(context).replaceAll('{categoryName}', categoryName),
      confirmButtonText: AppLocale.okButtonText.getString(context),
      cancelButtonText: AppLocale.cancelButtonText.getString(context),
    );

    if (confirmed == true && mounted) {
      setState(() {
        final todosToMove = _currentUser!.todosByCategories.remove(categoryName);
        if (todosToMove != null) {
          _currentUser!.todosByCategories['All'] = [..._currentUser!.todosByCategories['All'] ?? [], ...todosToMove];
           // Update category for moved todo items
          _currentUser!.todosByCategories['All']?.forEach((todo) {
            if (todosToMove.any((movedTodo) => movedTodo.id == todo.id)) {
              todo.category = "All";
            }
          });
        }
        FirebaseRepoInteractor.I.saveUser(_currentUser!);
        _initializeTabs(); // Re-initialize tabs
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.categoryDeletedSnackbar.getString(context).replaceAll('{categoryName}', categoryName))));
      });
    }
  }

  void _showShareDialog(String categoryId, String categoryName, SharedListConfig? existingConfig) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ShareListDialog(
          categoryId: categoryId, // For new share, this is categoryName. For existing, it's config.id.
          categoryName: categoryName, // Display name
          existingConfig: existingConfig,
        );
      },
    ).then((_) => _loadCurrentUserAndInitializeTabs()); // Refresh tabs after dialog closes
  }

  void _promptToJoinSharedList() {
    if (fb_auth.FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.loginToJoinPrompt.getString(context))));
      return;
    }
    DialogHelper.showTextInputDialog(
      context,
      title: AppLocale.joinSharedListMenuButtonName.getString(context),
      hintText: AppLocale.enterLinkPathHint.getString(context),
      confirmButtonText: AppLocale.joinButtonText.getString(context),
      cancelButtonText: AppLocale.cancelButtonText.getString(context),
      onConfirm: (linkPath) async {
        if (linkPath.isNotEmpty) {
          try {
            final updatedUser = await FirebaseRepoInteractor.I.joinSharedList(linkPath);
            if (updatedUser != null && mounted) {
               final config = updatedUser.sharedListsConfigs.firstWhereOrNull((c) => c.shortLinkPath == linkPath);
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocale.joinListSuccess.getString(context).replaceAll('{listName}', config?.listNameInSharedCollection ?? ''))));
              _loadCurrentUserAndInitializeTabs(); // Refresh
            } else if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.joinListError.getString(context))));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${AppLocale.joinListError.getString(context)}: ${e.toString()}")));
            }
          }
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _tabController == null || _tabs.isEmpty) {
      return Scaffold(appBar: AppBar(), body: Center(child: CircularProgressIndicator()));
    }

    final currentTab = _tabs.isNotEmpty ? _tabs[_tabController!.index] : _TabData(id: "All", name: "All");
    List<TodoListItem> currentTodos = [];
    if (currentTab.isShared) {
      currentTodos = _sharedListTodos[currentTab.id] ?? [];
    } else {
      currentTodos = _currentUser!.todosByCategories[currentTab.id] ?? [];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.todoLater.getString(context)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab.name)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: AppLocale.addCategoryTooltip.getString(context),
            onPressed: _addCategory,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == _kMenuSettings) {
                Navigator.pushNamed(context, '/settings');
              } else if (value == _kMenuArchived) {
                // Navigator.pushNamed(context, '/archived'); // Archive not fully implemented
              } else if (value == _kMenuJoinList) {
                 _promptToJoinSharedList();
              } else if (value.startsWith(_kMenuShareCategory)) {
                final tab = _tabs[_tabController!.index];
                if (!tab.isShared) { // Can only share personal categories initially
                   _showShareDialog(tab.id, tab.name, null); // tab.id is categoryName here
                }
              } else if (value.startsWith(_kMenuManageShare)) {
                 final tab = _tabs[_tabController!.index];
                 if (tab.isShared && tab.config != null) {
                    _showShareDialog(tab.id, tab.name, tab.config); // tab.id is sharedListId here
                 }
              } else if (value.startsWith(_kMenuRenameCategory)) {
                final tab = _tabs[_tabController!.index];
                if (!tab.isShared) _renameCategory(tab.id); // tab.id is categoryName
              } else if (value.startsWith(_kMenuDeleteCategory)) {
                final tab = _tabs[_tabController!.index];
                if (!tab.isShared && tab.id != "All") _deleteCategory(tab.id); // tab.id is categoryName
              }
            },
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<String>> items = [
                PopupMenuItem<String>(value: _kMenuSettings, child: Text(AppLocale.settings.getString(context))),
                // PopupMenuItem<String>(value: _kMenuArchived, child: Text(AppLocale.archivedTodos.getString(context))), // Archive not fully implemented
                PopupMenuItem<String>(value: _kMenuJoinList, child: Text(AppLocale.joinSharedListMenuButtonName.getString(context))),
              ];
              // Add dynamic menu items for current tab
              final currentTab = _tabs[_tabController!.index];
              if (!currentTab.isShared) { // Personal List specific options
                items.add(PopupMenuItem<String>(value: _kMenuShareCategory, child: Text(AppLocale.shareCategoryButtonTooltip.getString(context))));
                if (currentTab.id != "All") { // Cannot rename/delete "All"
                  items.add(PopupMenuItem<String>(value: _kMenuRenameCategory, child: Text(AppLocale.renameCategoryMenuButton.getString(context))));
                  items.add(PopupMenuItem<String>(value: _kMenuDeleteCategory, child: Text(AppLocale.deleteCategoryMenuButton.getString(context))));
                }
              } else { // Shared List specific options
                 if (currentTab.config?.adminUserId == _currentUser?.id) { // Only admin can manage
                    items.add(PopupMenuItem<String>(value: _kMenuManageShare, child: Text(AppLocale.manageShareSettings.getString(context))));
                 }
              }
              return items;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                List<TodoListItem> todosForThisTab = [];
                if (tab.isShared) {
                  todosForThisTab = _sharedListTodos[tab.id] ?? [];
                } else {
                  todosForThisTab = _currentUser!.todosByCategories[tab.id] ?? [];
                }
                 // Sort todos: incomplete first, then by creation date descending
                todosForThisTab.sort((a, b) {
                  if (a.isDone != b.isDone) {
                    return a.isDone ? 1 : -1;
                  }
                  return b.createdDate.compareTo(a.createdDate);
                });

                if (todosForThisTab.isEmpty) {
                  return Center(child: Text(
                    tab.isShared ? AppLocale.noTasksInSharedList.getString(context) : AppLocale.motivationalSentence5.getString(context)
                  ));
                }
                return ListView.builder(
                  itemCount: todosForThisTab.length,
                  itemBuilder: (context, index) {
                    final todo = todosForThisTab[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        leading: Checkbox(
                          value: todo.isDone,
                          onChanged: (bool? value) => _toggleTodoStatus(todo),
                        ),
                        title: Text(
                          todo.text,
                          style: TextStyle(
                            decoration: todo.isDone ? TextDecoration.lineThrough : null,
                            color: todo.isDone ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          "${AppLocale.timeFewSecondsAgo.getString(context)} - ${todo.category}", // Placeholder for relative time
                           style: TextStyle(color: todo.isDone ? Colors.grey : null),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _editTodo(todo)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteTodo(todo)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          // if (_isBannerAdLoaded && _bannerAd != null) // Ads commented out
          //   Container(
          //     alignment: Alignment.center,
          //     width: _bannerAd!.size.width.toDouble(),
          //     height: _bannerAd!.size.height.toDouble(),
          //     child: AdWidget(ad: _bannerAd!),
          //   ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    focusNode: _todoFocusNode,
                    decoration: InputDecoration(
                      hintText: AppLocale.enterTodoTextPlaceholder.getString(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    ),
                    onSubmitted: (_) => _addOrUpdateTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () => _addOrUpdateTodo(),
                  child: const Icon(Icons.add),
                  tooltip: AppLocale.addTodo.getString(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}