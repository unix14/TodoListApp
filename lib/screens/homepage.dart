import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/common/DialogHelper.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/date_extensions.dart';
import 'package:flutter_example/common/dialog_extensions.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:flutter_example/common/home_widget_helper.dart';
import 'package:flutter_example/common/stub_data.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/mixin/pwa_installer_mixin.dart';
import 'package:flutter_example/models/todo_category.dart'; // Updated import
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/screens/onboarding.dart';
import 'package:flutter_example/screens/settings.dart';
import 'package:flutter_example/widgets/rounded_text_input_field.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String kRenameCategoryMenuButtonName = 'rename_category'; // Will be removed
const String kDeleteCategoryMenuButtonName = 'delete_category'; // Will be removed
const String kCategoryOptionsMenuButtonName = 'category_options_menu_button';

// Top-level helper function for tab text color
Color _getTabTextColorHelper(TodoCategory category) {
  // Assuming category.color always has a value due to model default.
  // If category.color is the default white (0xFFFFFFFF), make tab text white.
  // Otherwise, use the category color.
  if (category.color == 0xFFFFFFFF) {
    return Colors.white; // Text color for white categories is now white
  } else {
    return Color(category.color); // Text color is the category color
  }
}

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
  List<TodoCategory> _categoryTabsList = []; // Updated type
  List<TodoCategory> _customCategories = []; // Updated type
  bool _isPromptingForCategory = false;

  // Search state
  bool _isSearching = false;
  String _searchQuery = "";
  late FocusNode _searchFocusNode;
  late TextEditingController _searchController;
  List<TodoListItem> _searchResults = []; // Initialize search results list
  static const String HEADER_PREFIX = "HEADER::";

  Color _currentIndicatorColor = Colors.white; // Default indicator color


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

  Widget searchIcon = const Icon(Icons.search);

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
    _initializeTabs().then((_) {
      // Initialize indicator color after tabs are set up
      _updateCurrentIndicatorColor();
    });
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
    // _customCategories will be List<TodoCategory> after EncryptedSharedPreferencesHelper is updated
    _customCategories = await EncryptedSharedPreferencesHelper.loadCategories();

    // This part should be synchronous and use the updated context from didChangeDependencies
    List<TodoCategory> newCategoryTabsList = [ // Updated type
      TodoCategory(name: AppLocale.all.getString(context), color: 0xFFFFFFFF), // Used TodoCategory
      ..._customCategories
    ];

    // Ensure previousIndex is valid for the new categories length
    // The TabController length will be newCategoryTabsList.length + 1 (for the '+' tab)
    // So, valid indices for actual categories are 0 to newCategoryTabsList.length - 1
    // and the '+' tab will be at index newCategoryTabsList.length.
    if (previousIndex >= newCategoryTabsList.length + 1) {
      previousIndex = 0; // Default to first tab if out of bounds
    }

    // If previous index was the '+' tab (which is at newCategoryTabsList.length after new list is formed)
    // or if it points to an index that would be the '+' tab in the new setup.
    if (previousIndex == newCategoryTabsList.length) {
      previousIndex = 0;
    }

    if (previousIndex >
        newCategoryTabsList.length) { // If it's beyond the '+' tab index
      previousIndex = 0;
    }

    if (newCategoryTabsList.isEmpty) { // Should not happen due to "All" category, but good for safety
      previousIndex = 0;
    }


    TabController newTabController = TabController(
      length: newCategoryTabsList.length + 1, // +1 for the '+' tab
      vsync: this,
      initialIndex: previousIndex,
    );
    newTabController.addListener(_handleTabSelection);

    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _categoryTabsList = newCategoryTabsList;
        _tabController = newTabController;
        // Update indicator color after new controller is set
        // _updateCurrentIndicatorColor(); // This will be called by the listener after index change
      });
      // Call explicitly after setState if the index might not have changed but list did (e.g. category rename)
      _updateCurrentIndicatorColor();
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
    if (_tabController!.index == _categoryTabsList.length) {
      final previousIndex = _tabController!.previousIndex;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController != null && _tabController!.index == _categoryTabsList.length) {
          _isPromptingForCategory = true;
          _promptForNewCategory(selectedIndexToRestore: previousIndex).whenComplete(() {
             if (mounted) { // Reset flag and update indicator after dialog closes
                _isPromptingForCategory = false;
                _updateCurrentIndicatorColor();
             }
          });
        }
      });
    } else {
       _updateCurrentIndicatorColor(); // Update for regular tab changes
      if (_tabController!.indexIsChanging) {
        // setState is called by _updateCurrentIndicatorColor if needed
      }
    }
  }

  void _updateCurrentIndicatorColor() {
    if (!mounted || _tabController == null) return;

    Color newColor;
    if (_tabController!.index < _categoryTabsList.length) {
      final selectedCategory = _categoryTabsList[_tabController!.index];
      // As per requirement: "if white, then white it is" for indicator.
      newColor = Color(selectedCategory.color);
    } else {
      // "+" tab or out of bounds
      newColor = Theme.of(context).indicatorColor; // Default for "+" tab
    }

    if (_currentIndicatorColor != newColor) {
      setState(() {
        _currentIndicatorColor = newColor;
      });
    }
  }


  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    myBanner?.dispose();
    _todoLineFocusNode.dispose(); // Dispose of the FocusNode
    _textEditingController.dispose(); // Dispose the text controller
    _searchFocusNode.dispose();
    _searchController.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_onKey);
    super.dispose();
  }

  // late String randomKey;
  Map<int, String> randomKeysMap = {};

  @override
  void initState() {
    super.initState();
    _textEditingController =
        TextEditingController(); // Initialize the controller
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _loadingData = loadList();
    if (false) initAds();
    initializeInstallPrompt();
    // Automatically show the install prompt if available
    if (isInstallable()) {
      showInstallPrompt();
    }
    // _initializeTabs will be called from didChangeDependencies, which then calls _updateCurrentIndicatorColor
    ServicesBinding.instance.keyboard.addHandler(_onKey);
    int categoryIndex = getCategoryIndex();
    randomKeysMap.putIfAbsent(categoryIndex, _loadRandomMotivational);
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

  int getCategoryIndex() {
    if (_tabController == null || _categoryTabsList.isEmpty) {
      return -1;
    }
    // Ensure index is valid for _categoryTabsList before accessing.
    // _tabController.index can be out of bounds if tabs are being re-initialized,
    // or if it points to the "+" button which is not a category in _categoryTabsList list.
    if (_tabController!.index < 0 ||
        _tabController!.index >= _categoryTabsList.length) {
      return -1;
    }
    return _tabController!.index;
  }

  bool _isCurrentCategoryCustom() {
    int categoryIndex = getCategoryIndex();
    if (categoryIndex < 0) { // Should not happen if "All" exists
      return false;
    }
    // Check if the selected category is NOT the "All" category.
    // "All" category is always at index 0 of _categoryTabsList
    return _tabController!.index != 0;
  }

  bool _onKey(KeyEvent event) {
    final key = event.logicalKey.keyLabel;

    if (event is KeyDownEvent) {
      print("Key down: $key");
      if (key == "Escape") {
        setState(() {
          _isSearching = false;
          _searchQuery = "";
          _searchController.clear();
          _searchResults = []; // Clear search results when exiting search mode
        });
      }
    } else if (event is KeyUpEvent) {
      print("Key up: $key");
    } else if (event is KeyRepeatEvent) {
      print("Key repeat: $key");
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    int categoryIndex = getCategoryIndex();
    randomKeysMap.putIfAbsent(categoryIndex, _loadRandomMotivational);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: AppLocale.searchTodosHint.getString(context),
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
            _performSearch(query);
          },
        )
            : Text(AppLocale.title.getString(context)),
        bottom: _isSearching // Hide TabBar when searching
            ? null
            : _tabController == null
            ? null
            : PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Align(
            alignment: currentLocaleStr == "he"
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: _currentIndicatorColor, // Use state variable for indicator color
              tabs: [
                ..._categoryTabsList
                    .map((TodoCategory category) {
                      String tabText = category.name.substring(0, min(category.name.length, MAX_CHARS_IN_TAB_BAR)) +
                                     (category.name.length > MAX_CHARS_IN_TAB_BAR ? "..." : "");
                      return Tab(
                        child: Text(
                          tabText,
                          style: TextStyle(color: _getTabTextColorHelper(category)), // Updated call site
                        ),
                      );
                    }
                )
                    .toList(),
                Tab(
                    icon: Tooltip(
                        message: AppLocale.addCategoryTooltip.getString(
                            context),
                        child: const Icon(Icons.add))), // "+" icon tab retains default color
              ],
            ),
          ),
        ),
        leading: _isSearching ? searchIcon : IconButton(
          icon: const Icon(Icons.shuffle),
          onPressed: _showRandomTask, // Call renamed method
          tooltip: AppLocale.randomTaskMenuButton.getString(context),
          padding: const EdgeInsets.all(0),
        ),
        actions: _isSearching
            ? [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: AppLocale.closeSearchTooltip.getString(context),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchQuery = "";
                _searchController.clear();
                _searchResults = []; // Clear search results
              });
              // Potentially call _performSearch("") if you want to reset the list
            },
          ),
        ] : _buildDefaultAppBarActions(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: _tabController == null || _categoryTabsList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: List<Widget>.generate(
                  _tabController?.length ?? 0, // Ensure controller is not null
                      (index) {
                    if (_tabController == null || index >= _categoryTabsList.length) {
                      // This is for the "+" tab, or if controller is null initially
                      return Container(); // Empty view for the action tab
                    }
                    // Actual category view
                    final currentCategoryForTab = _categoryTabsList[index];

                    return FutureBuilder<List<TodoListItem>>(
                      future: _loadingData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else {
                          final allLoadedItems = snapshot.data ?? [];
                          items =
                              allLoadedItems; // Keep the main 'items' list updated

                          // Determine items to display based on search state and query
                          List<TodoListItem> itemsToDisplayOrSearchIn;
                          if (currentCategoryForTab.name ==
                              AppLocale.all.getString(context)) {
                            itemsToDisplayOrSearchIn = allLoadedItems.reversed
                                .where((item) => !item.isArchived)
                                .toList();
                          } else {
                            itemsToDisplayOrSearchIn = allLoadedItems.reversed
                                .where((item) =>
                            !item.isArchived &&
                                item.category == currentCategoryForTab.name)
                                .toList();
                          }

                          Widget listContent;

                          if (_isSearching) {
                            if (_searchQuery.isEmpty) {
                              // Searching but query is empty: show original list for the category
                              if (itemsToDisplayOrSearchIn.isEmpty) {
                                listContent = Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      (randomKeysMap[categoryIndex])?.getString(context) ?? _loadRandomMotivational(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 18,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                );
                              } else if (itemsToDisplayOrSearchIn.isNotEmpty) {
                                String taskCountString;
                                if (itemsToDisplayOrSearchIn.length == 1) {
                                  taskCountString =
                                      AppLocale.tasksCountSingular.getString(
                                          context);
                                } else {
                                  taskCountString =
                                      AppLocale.tasksCount.getString(context)
                                          .replaceAll('{count}',
                                          itemsToDisplayOrSearchIn.length
                                              .toString());
                                }
                                listContent = Expanded(
                                  child: ListView.builder(
                                    itemCount: itemsToDisplayOrSearchIn
                                        .length + 1,
                                    itemBuilder: (context, index) {
                                      if(index == 0) {
                                        return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0, horizontal: 16.0),
                                            child: Text(taskCountString,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontSize: 13.0,
                                                    color: Colors.blueGrey,
                                                    fontWeight: FontWeight.w500)),
                                          );
                                      }
                                      int itemIndex = index - 1;
                                      return getListTile(
                                            itemsToDisplayOrSearchIn[itemIndex]);
                                    }
                                  ),
                                );
                              } else {
                                listContent =
                                    ListView(); // Empty list for non-"All" categories that are empty
                              }
                            } else if (_searchResults
                                .isEmpty) { // Query is not empty, but results are empty
                              listContent = Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    AppLocale.noResultsFound.getString(context)
                                        .replaceAll('{query}', _searchQuery),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                ),
                              );
                            } else { // Query is not empty, and results are found
                              String taskCountString;
                              if (_searchResults.length == 1) {
                                taskCountString =
                                    AppLocale.tasksCountSingular.getString(
                                        context);
                              } else {
                                taskCountString =
                                    AppLocale.tasksFoundCount.getString(context)
                                        .replaceAll('{count}', _searchResults
                                        .where((TodoListItem item) =>
                                    item.text.startsWith(HEADER_PREFIX) ==
                                        false)
                                        .length
                                        .toString());
                              }
                              listContent = ListView.builder(
                                itemCount: _searchResults.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 16.0),
                                        child: Text(taskCountString,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 13.0,
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    );
                                  }
                                  int searchIdx = index - 1;
                                  final item = _searchResults[searchIdx];
                                  if (item.text.startsWith(HEADER_PREFIX)) {
                                    String rawHeaderText = item.text.substring(
                                        HEADER_PREFIX.length);
                                    String displayHeaderText;
                                    // Ensure AppLocale.resultsInCategory is a string before using string methods.
                                    // It should be AppLocale.resultsInCategory.getString(context) for localization.
                                    // For now, assuming AppLocale.resultsInCategory is a key and needs .getString(context)
                                    // This logic will be reviewed in search logic update step.
                                    String resultsInCategoryKey = AppLocale.resultsInCategory.getString(context);
                                    if (rawHeaderText.startsWith("$resultsInCategoryKey::")) {
                                      String catName = rawHeaderText.substring(
                                          ("$resultsInCategoryKey::").length);
                                      displayHeaderText = resultsInCategoryKey.replaceAll('{categoryName}', catName);
                                    } else {
                                      displayHeaderText = rawHeaderText.replaceAll("::", " ");
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      child: Text(displayHeaderText,
                                          style: const TextStyle(fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey)),
                                    );
                                  }
                                  return getListTile(item);
                                },
                              );
                            }
                          } else { // Not searching: Normal category view logic
                            if (currentCategoryForTab.name ==
                                AppLocale.all.getString(context) &&
                                itemsToDisplayOrSearchIn.isEmpty) {
                              listContent = Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    (randomKeysMap[categoryIndex])?.getString(context) ?? _loadRandomMotivational(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                              );
                            } else if (itemsToDisplayOrSearchIn.isNotEmpty) {
                              String taskCountString;
                              if (itemsToDisplayOrSearchIn.length == 1) { //
                                taskCountString =
                                    AppLocale.tasksCountSingular.getString(
                                        context);
                              } else {
                                taskCountString =
                                    AppLocale.tasksCount.getString(context)
                                        .replaceAll('{count}',
                                        itemsToDisplayOrSearchIn.length
                                            .toString());
                              }
                              //
                              listContent = Expanded(
                                child: ListView.builder(
                                  itemCount: itemsToDisplayOrSearchIn
                                      .length + 1,
                                  itemBuilder: (context, index) {
                                    if(index == 0) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 16.0),
                                        child: Text(taskCountString,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 13.0,
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.w500)),
                                      );
                                    }
                                    int itemIndex = index - 1;
                                    return getListTile(
                                        itemsToDisplayOrSearchIn[itemIndex]);
                                  }
                                ),
                              );
                            } else {
                              listContent = Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    (randomKeysMap[categoryIndex])?.getString(context) ?? _loadRandomMotivational(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ); // Empty list view for non-"All" categories that are empty
                            }
                          }
                          return listContent;
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
          if (!_isSearching) // Conditionally render the input field area
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
      floatingActionButton: (!_isSearching &&
          enteredAtLeast1Todo) // Updated condition
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
      String? currentCategoryName;
      if (_tabController != null && _tabController!.index < _categoryTabsList.length) {
        final selectedCategory = _categoryTabsList[_tabController!.index];
        if (selectedCategory.name != AppLocale.all.getString(context)) {
          currentCategoryName = selectedCategory.name;
        }
      }

      setState(() {
        items.add(TodoListItem(inputText.trim(), category: currentCategoryName));
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
          AppLocale.emptyTodoDialogTitle.getString(context),
          AppLocale.emptyTodoDialogMessage.getString(context),
              () {
            // Ok
            Navigator.of(context).pop(); // dismiss dialog
          }, null);
    }
  }

  void _updateList() async {
    // Convert the current list to JSON
    var listAsStr = jsonEncode(items);
    await EncryptedSharedPreferencesHelper.setString(
        kAllListSavedPrefs, listAsStr);
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

    updateHomeWidget();
    print(
        '[HomeWidget] Sent update request to widget provider after updating list.');
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
                                  getFormattedDate(
                                      todo.dateTime.toString(), context),
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
                                          AppLocale.doUwant2Delete.getString(
                                              context),
                                          AppLocale.thisCantBeUndone.getString(
                                              context), () {
                                        // dismiss dialog
                                        setState(() {
                                          items.remove(todo);
                                          // itemOnEditIndex = -1; // Removed
                                          if (_editingTodo == todo) {
                                            _setEditingTodo(
                                                null); // Clear editing state if deleted item was being edited
                                          }
                                          _updateList();
                                        });
                                        Navigator.of(context).pop();
                                      }, () {
                                        // Cancel
                                        Navigator.of(context)
                                            .pop(); // dismiss dialog
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
    var listStr = await EncryptedSharedPreferencesHelper.getString(
        kAllListSavedPrefs) ?? "";
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

        print("the result for ${currentUser!.uid} is ${myCurrentUser
            ?.todoListItems?.length ?? -1}");
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
          _saveTodo(
              currentTodo, _textEditingController.text); // Save current changes
        } else { // Not editing this one, or not editing at all
          if (_editingTodo != null) { // If editing another item
            _saveTodo(_editingTodo!,
                _textEditingController.text); // Save changes to the other item
            // _setEditingTodo(null); // No longer needed here as _saveTodo handles it
          }
          _showTodoContextMenu(
              currentTodo); // Then show context menu for current one
        }
      },
      onTap: () {
        if (isEditMode(currentTodo)) {
          // Tapping an item already in inline edit mode: do nothing here.
          // Focus should be handled by the TextField itself or its autofocus.
          // Saving is done via the leading Save icon or TextField's onSubmitted.
        } else if (_editingTodo != null) { // If editing a DIFFERENT item
          _saveTodo(
              _editingTodo!, _textEditingController.text); // Save the other one
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
          subtitle: Builder( // Use Builder to ensure context is available for AppLocale
            builder: (context) {
              List<Widget> subtitleChildren = [
                Text(
                  getFormattedDate(currentTodo.dateTime.toString(), context),
                  style: TextStyle(
                    decoration: currentTodo.isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ];

              bool isAllTab = _tabController != null &&
                              _categoryTabsList.isNotEmpty &&
                              _tabController!.index < _categoryTabsList.length && // Check index bounds
                              _categoryTabsList[_tabController!.index].name == AppLocale.all.getString(context);

              if (isAllTab && currentTodo.category != null) {
                TodoCategory? itemCategory = _customCategories.firstWhere( // Corrected type
                  (TodoCategory cat) => cat.name == currentTodo.category,
                  orElse: () => _categoryTabsList.firstWhere(
                                (TodoCategory cat) => cat.name == currentTodo.category,
                                orElse: () => TodoCategory(name: currentTodo.category!, color: 0xFF000000),
                              ),
                );

                if (itemCategory != null) {
                  Color chipColor = itemCategory.color == 0xFFFFFFFF
                                   ? (Colors.grey[300] ?? Colors.grey)
                                   : Color(itemCategory.color);
                  // Determine text color based on chip background color brightness
                  // This is a simple heuristic, might need refinement for more complex color palettes
                  bool isDark = chipColor.computeLuminance() < 0.5;
                  Color textColor = isDark ? Colors.white : Colors.black;

                  subtitleChildren.add(const SizedBox(width: 8)); // Spacing
                  subtitleChildren.add(
                    GestureDetector(
                      onTap: () {
                        final categoryIndex = _categoryTabsList.indexWhere(
                            (cat) => cat.name == currentTodo.category);
                        if (categoryIndex != -1) {
                          _tabController?.animateTo(categoryIndex);
                        }
                      },
                      child: Chip(
                        label: Text(
                          currentTodo.category!,
                          style: TextStyle(fontSize: 11, color: textColor), // Adjusted fontSize
                        ),
                        backgroundColor: chipColor,
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0.0), // Adjusted padding
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelPadding: EdgeInsets.zero, // Use chip's padding
                        visualDensity: VisualDensity.compact,
                        elevation: 1.0, // Set elevation
                        // shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade400, width: 0.5)), // Optional border
                      ),
                    ),
                  );
                }
              }
              // Ensure the Row uses CrossAxisAlignment.center for vertical alignment
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: subtitleChildren,
              );
            }
          ),
          trailing: null,
        ),
      ),
    );
  }

  void _saveTodo(TodoListItem todo, String newText) {
    if (newText
        .trim()
        .isEmpty) {
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
    if (_tabController != null && _tabController!.index < _categoryTabsList.length) {
      currentCategoryName = _categoryTabsList[_tabController!.index].name;
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

    if(availableTasks.isEmpty) {
      // if current category is empty
      availableTasks = items
          .where((item) => !item.isArchived && !item.isChecked)
          .toList();
    }

    if (availableTasks.isEmpty) {
      // all lists are empty
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

  Future<TodoCategory?> _promptForNewCategory({int? selectedIndexToRestore}) async {
    TodoCategory? newCategoryFromDialog;

    // Local state for the dialog itself
    Color selectedColorForNewCategory = const Color(0xFFFFFFFF); // Default to white
    bool isExpanded = false;
    TextEditingController nameController = TextEditingController();
    GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Set _isPromptingForCategory true before showing dialog
    // and ensure it's reset in finally block or after dialog closes.
    // This flag is used in _handleTabSelection to prevent re-triggering.
    // setState(() { _isPromptingForCategory = true; }); // Already handled by caller in _handleTabSelection

    randomKeysMap.clear();

    newCategoryFromDialog = await showDialog<TodoCategory>(
      context: context,
      // barrierDismissible: true, // Allow dismiss by tapping outside, will return null
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(AppLocale.addCategoryDialogTitle.getString(dialogContext)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(hintText: AppLocale.categoryNameHintText.getString(dialogContext)),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocale.categoryNameEmptyError.getString(dialogContext);
                          }
                          if (_customCategories.any((TodoCategory cat) => cat.name.toLowerCase() == value.trim().toLowerCase())) {
                            return AppLocale.categoryNameExistsError.getString(dialogContext);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Tooltip(
                            message: AppLocale.selectColorTooltip.getString(dialogContext),
                            child: InkWell(
                              onTap: () async {
                                final int? pickedColorValue = await _selectCategoryColor(
                                  dialogContext, // Use dialogContext here
                                  TodoCategory(name: "", color: selectedColorForNewCategory.value),
                                );
                                if (pickedColorValue != null) {
                                  setStateDialog(() {
                                    selectedColorForNewCategory = Color(pickedColorValue);
                                  });
                                }
                              },
                              child: CircleAvatar(
                                backgroundColor: selectedColorForNewCategory,
                                radius: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(AppLocale.categoryColorLabel.getString(dialogContext)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setStateDialog(() {
                                isExpanded = !isExpanded;
                              });
                            },
                            child: Text(isExpanded ? AppLocale.collapseButtonText.getString(dialogContext) : AppLocale.expandButtonText.getString(dialogContext)),
                          ),
                        ],
                      ),
                      // Optional: if (isExpanded) ... show more UI ...
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocale.cancelButtonText.getString(dialogContext)),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(null); // Return null if cancelled
                  },
                ),
                TextButton(
                  child: Text(AppLocale.addButtonText.getString(dialogContext)),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newName = nameController.text.trim();
                      final newCategory = TodoCategory(name: newName, color: selectedColorForNewCategory.value);
                      Navigator.of(dialogContext).pop(newCategory); // Return the new category
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (newCategoryFromDialog != null) {
      setState(() {
        _customCategories.add(newCategoryFromDialog!);
        EncryptedSharedPreferencesHelper.saveCategories(_customCategories);

        if (myCurrentUser != null) {
          myCurrentUser!.categories = List<TodoCategory>.from(_customCategories);
          FirebaseRepoInteractor.instance.updateUserData(myCurrentUser!);
        }
        updateHomeWidget();
        // Use categoryAddedSnackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.categoryAddedSnackbar.getString(context).replaceAll('{categoryName}', newCategoryFromDialog.name))),
        );
        print('[HomeWidget] Sent update request to widget provider after adding category.');
      });

      await _initializeTabs();
      if(mounted && _tabController != null) {
        final newCategoryIndexInTabs = _categoryTabsList.indexWhere((TodoCategory cat) => cat.name == newCategoryFromDialog!.name);
        if (newCategoryIndexInTabs != -1) {
          _tabController!.animateTo(newCategoryIndexInTabs);
        } else {
          _tabController!.animateTo(0);
        }
      }
    } else {
      if (selectedIndexToRestore != null && _tabController != null) {
        if (_tabController!.index == _categoryTabsList.length && mounted) {
          _tabController!.animateTo(selectedIndexToRestore);
        }
      }
    }
    return newCategoryFromDialog;
  }

  void _showTodoContextMenu(TodoListItem todoItem) {
    // Ensure any active edit is saved before showing context menu for potentially different item
    // This is now handled by onLongPress before calling _showTodoContextMenu if _editingTodo is not null.

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
                  // Logic to save previous item is handled by onLongPress or onTap before calling this.
                  // Or, if called directly, _setEditingTodo should handle it.
                  // For now, assuming _setEditingTodo will be enhanced or caller handles saving.
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
       "'${todoItem.text}' ${AppLocale.willBeDeleted.getString(context)} ${AppLocale.thisCantBeUndone.getString(context)}",
        () {
      Navigator.of(context).pop();
      _setEditingTodo(null);
      setState(() {
        items.remove(todoItem);
        _updateList();
      });
    }, () {
      Navigator.of(context).pop();
    },
       okBtnTxt: AppLocale.delete.getString(context),
       okColor: Colors.red,
     );
  }

  void _promptMoveToCategory(TodoListItem todoItem) async {
    List<TodoCategory> availableCategories = List.from(_customCategories);

    showDialog<TodoCategory?>(
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
            ...availableCategories.map((TodoCategory category) {
              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(dialogContext, category);
                },
                child: Text(category.name),
              );
            }).toList(),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, TodoCategory(name: kAddNewCategoryOption));
              },
              child: Text(AppLocale.addNewCategoryMenuItem.getString(dialogContext)),
            ),
          ],
        );
      },
    ).then((selectedCategoryOrAction) {
      if (selectedCategoryOrAction?.name == kAddNewCategoryOption) {
        _promptForNewCategory().then((newlyCreatedCategory) { // Changed variable name for clarity
          if (newlyCreatedCategory != null && newlyCreatedCategory.name.isNotEmpty) { // Check new object
            setState(() {
              todoItem.category = newlyCreatedCategory.name; // Use name from object
              _updateList();
            });
            _initializeTabs();

            final snackBar = SnackBar(
              content: Text(
                AppLocale.itemMovedSnackbar.getString(context).replaceAll('{categoryName}', newlyCreatedCategory.name), // Use name from object
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        });
      } else {
        final selectedCategoryName = selectedCategoryOrAction?.name;

        if (selectedCategoryName != todoItem.category) {
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
    });
  }

  Future<TodoCategory?> _promptRenameCategory(TodoCategory oldCategory) async {
    final TextEditingController categoryController = TextEditingController(text: oldCategory.name);
    final formKey = GlobalKey<FormState>();
    TodoCategory? renamedCategory;

    try {
      String? newNameStr = await showDialog<String>(
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
                        if (newNameTrimmed.toLowerCase() != oldCategory.name.toLowerCase() &&
                            _customCategories.any((cat) => cat.name.toLowerCase() == newNameTrimmed.toLowerCase())) {
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

      if (newNameStr != null && newNameStr != oldCategory.name) {
        renamedCategory = TodoCategory(name: newNameStr, color: oldCategory.color);
        setState(() {
          final oldCategoryIndex = _customCategories.indexWhere((cat) => cat.name.toLowerCase() == oldCategory.name.toLowerCase());
          if (oldCategoryIndex != -1) {
            _customCategories[oldCategoryIndex] = renamedCategory!;
          }

          for (var item in items) {
            if (item.category == oldCategory.name) {
              item.category = renamedCategory!.name;
            }
          }

          EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
          if (myCurrentUser != null) {
            myCurrentUser!.categories = List<TodoCategory>.from(_customCategories);
            FirebaseRepoInteractor.instance.updateUserData(myCurrentUser!);
          }
          updateHomeWidget();
          _updateList();
          _initializeTabs();

          final snackBar = SnackBar(
            content: Text(
              AppLocale.categoryRenamedSnackbar.getString(context)
                  .replaceAll('{oldName}', oldCategory.name)
                  .replaceAll('{newName}', newNameStr),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      } else if (newNameStr != null && newNameStr == oldCategory.name) {
        renamedCategory = oldCategory;
      }
      return renamedCategory;

    } catch (e) {
      print("Error in _promptRenameCategory: $e");
      return null;
    }
  }

  void _toggleSearchUI() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchQuery = "";
        _searchController.clear();
        _searchResults = [];
      }
    });
    _performSearch(_searchQuery);
    debugPrint("Toggle Search UI: _isSearching is now $_isSearching");
  }

  void _performSearch(String query) {
    final String lowerCaseQuery = query.toLowerCase().trim();
    List<TodoListItem> newResults = [];

    if (!_isSearching || lowerCaseQuery.isEmpty) {
       setState(() {
        _searchResults = [];
      });
      return;
    }

    final TodoCategory currentCategoryObj = (_tabController != null && _tabController!.index < _categoryTabsList.length)
        ? _categoryTabsList[_tabController!.index]
        : TodoCategory(name: AppLocale.all.getString(context));

    final bool isAllTab = currentCategoryObj.name == AppLocale.all.getString(context);

    if (isAllTab) {
      newResults = items
          .where((item) =>
              !item.isArchived &&
              item.text.toLowerCase().contains(lowerCaseQuery))
          .toList();
    } else {
      for (TodoCategory otherCategory in _categoryTabsList) {
        final List<TodoListItem> otherCategoryMatches = items
            .where((item) =>
                !item.isArchived &&
                item.category == otherCategory.name &&
                item.text.toLowerCase().contains(lowerCaseQuery))
            .toList();

        if (otherCategoryMatches.isNotEmpty) {
          newResults.add(TodoListItem("$HEADER_PREFIX${AppLocale.resultsInCategory.getString(context).replaceAll('{categoryName}', otherCategory.name)}", category: otherCategory.name));
          newResults.addAll(otherCategoryMatches);
        }
      }
      final List<TodoListItem> uncategorizedMatches = items
          .where((item) =>
              !item.isArchived &&
              item.category == null &&
              item.text.toLowerCase().contains(lowerCaseQuery))
          .toList();

      if (uncategorizedMatches.isNotEmpty) {
        newResults.add(TodoListItem("$HEADER_PREFIX${AppLocale.resultsInAllCategory.getString(context)}", category: null));
        newResults.addAll(uncategorizedMatches);
      }
    }

    setState(() {
      _searchResults = newResults;
    });
    debugPrint("Performing search for: $query. Found ${_searchResults.length} results.");
  }

  List<Widget> _buildDefaultAppBarActions(BuildContext context) {
    final searchUIToggleButton = IconButton(
      icon: searchIcon,
      onPressed: _toggleSearchUI,
      tooltip: AppLocale.searchTodosTooltip.getString(context),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(),
    );

    final popupMenuButton = PopupMenuButton<String>(
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
        } else if (value == kRenameCategoryMenuButtonName) {
          if (_isCurrentCategoryCustom()) {
            final currentCategoryToRename = _categoryTabsList[_tabController!.index];
            _promptRenameCategory(currentCategoryToRename);
          }
        } else if (value == kDeleteCategoryMenuButtonName) {
          if (_isCurrentCategoryCustom()) {
            final categoryToDelete = _categoryTabsList[_tabController!.index];
            DialogHelper.showAlertDialog(
              context,
              AppLocale.deleteCategoryConfirmationTitle.getString(context),
              AppLocale.deleteCategoryConfirmationMessage.getString(context).replaceAll('{categoryName}', categoryToDelete.name)
              + AppLocale.deleteCategoryConfirmationMessageSuffix.getString(context),
              () {
                Navigator.of(context).pop();
                setState(() {
                  _customCategories.removeWhere((cat) => cat.name.toLowerCase() == categoryToDelete.name.toLowerCase());
                  for (var item in items) {
                    if (item.category == categoryToDelete.name) {
                      item.category = null;
                    }
                  }
                  EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
                  if (myCurrentUser != null) {
                    myCurrentUser!.categories = List<TodoCategory>.from(_customCategories);
                    FirebaseRepoInteractor.instance.updateUserData(myCurrentUser!);
                  }
                  updateHomeWidget();
                  print('[HomeWidget] Sent update request to widget provider after deleting category.');
                  _updateList();
                  _initializeTabs().then((_) {
                    if (mounted && _tabController != null && _tabController!.length > 0) {
                        _tabController!.animateTo(0);
                    }
                  });
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocale.categoryDeletedSnackbar.getString(context).replaceAll('{categoryName}', categoryToDelete.name)),
                ));
              },
              () {
                Navigator.of(context).pop();
              },
              okBtnTxt: AppLocale.delete.getString(context),
              okColor: Colors.red,
            );
          }
        } else if (value == kCategoryOptionsMenuButtonName) {
          if (_isCurrentCategoryCustom()) {
            final TodoCategory currentCategory = _categoryTabsList[_tabController!.index];
            _showCategoryOptionsDialog(currentCategory);
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
            value: kCategoryOptionsMenuButtonName,
            child: Row(
              children: [
                const Icon(Icons.settings_applications_outlined, color: Colors.blue),
                const SizedBox(width: 8.0),
                Text(AppLocale.categoryOptionsMenuItem.getString(context)),
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
        return popupMenuItems;
      },
    );
    return [searchUIToggleButton, popupMenuButton];
  }

  void _showCategoryOptionsDialog(TodoCategory originalCategory) {
    final TextEditingController nameController = TextEditingController(text: originalCategory.name);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    TodoCategory categoryBeingEdited = originalCategory;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(AppLocale.editCategoryDialogTitle(originalCategory.name).getString(dialogContext)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: AppLocale.categoryNameHintText.getString(dialogContext)),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocale.categoryNameEmptyError.getString(dialogContext);
                          }
                          final newNameTrimmed = value.trim();
                          if (newNameTrimmed.toLowerCase() == AppLocale.all.getString(dialogContext).toLowerCase()) {
                            return AppLocale.categoryNameExistsError.getString(dialogContext);
                          }
                          if (newNameTrimmed.toLowerCase() != originalCategory.name.toLowerCase() &&
                              _customCategories.any((TodoCategory cat) =>
                                  cat.name.toLowerCase() == newNameTrimmed.toLowerCase() &&
                                  cat.name.toLowerCase() != originalCategory.name.toLowerCase())) {
                            return AppLocale.categoryNameExistsError.getString(dialogContext);
                          }
                          return null;
                        },
                        onChanged: (value) {
                           // If live title update is desired for AlertDialog:
                           // setStateDialog(() { /* Update a local variable for title if needed */});
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocale.categoryColorLabel.getString(dialogContext) + ":"), // Added colon for clarity
                          Tooltip(
                            message: AppLocale.selectColorTooltip.getString(dialogContext),
                            child: InkWell(
                              onTap: () async {
                                final int? selectedColor = await _selectCategoryColor(dialogContext, categoryBeingEdited);
                                if (selectedColor != null) {
                                  setStateDialog(() {
                                    categoryBeingEdited = categoryBeingEdited.copyWith(color: selectedColor);
                                  });
                                }
                              },
                              child: CircleAvatar(backgroundColor: Color(categoryBeingEdited.color), radius: 14),
                            ),
                          ),
                        ],
                      ),
                      // Keep "Change Color" button or remove if CircleAvatar tap is enough
                       Padding( // Added padding for the button
                         padding: const EdgeInsets.symmetric(vertical: 8.0),
                         child: ElevatedButton(
                           child: const Text("Change Color"), // This string is not localized yet
                           onPressed: () async {
                             final int? selectedColor = await _selectCategoryColor(dialogContext, categoryBeingEdited);
                             if (selectedColor != null) {
                               setStateDialog(() {
                                 categoryBeingEdited = categoryBeingEdited.copyWith(color: selectedColor);
                               });
                             }
                           },
                         ),
                       ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text(AppLocale.deleteCategoryButtonText.getString(dialogContext), style: const TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _deleteCategoryFromOptionsDialog(originalCategory);
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
                ElevatedButton(
                  child: Text(AppLocale.saveButtonText.getString(dialogContext)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final String newNameFromController = nameController.text.trim();
                      final TodoCategory finalCategoryToSave = categoryBeingEdited.copyWith(name: newNameFromController);

                      bool nameChanged = finalCategoryToSave.name != originalCategory.name;
                      bool colorChanged = finalCategoryToSave.color != originalCategory.color;

                      if (nameChanged || colorChanged) {
                        int catIndexInCustom = _customCategories.indexWhere((c) => c.name.toLowerCase() == originalCategory.name.toLowerCase());

                        if (catIndexInCustom != -1) {
                          _customCategories[catIndexInCustom] = finalCategoryToSave;

                          if (nameChanged) {
                            for (var item in items) {
                              if (item.category == originalCategory.name) {
                                item.category = finalCategoryToSave.name;
                              }
                            }
                          }

                          await EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
                          if (myCurrentUser != null) {
                            int userCatIndex = myCurrentUser!.categories!.indexWhere((c) => c.name.toLowerCase() == originalCategory.name.toLowerCase());
                            if (userCatIndex != -1) {
                              myCurrentUser!.categories![userCatIndex] = finalCategoryToSave;
                            } else {
                               myCurrentUser!.categories = List<TodoCategory>.from(_customCategories);
                            }
                            await FirebaseRepoInteractor.instance.updateUserData(myCurrentUser!);
                          }
                          _updateList();
                          await _initializeTabs();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocale.categoryUpdatedSnackbar.getString(context).replaceAll('{categoryName}', finalCategoryToSave.name))),
                          );
                        }
                      }
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteCategoryFromOptionsDialog(TodoCategory categoryToDelete) {
     DialogHelper.showAlertDialog(
      context,
      AppLocale.deleteCategoryConfirmationTitle.getString(context),
      AppLocale.deleteCategoryConfirmationMessage.getString(context).replaceAll('{categoryName}', categoryToDelete.name) +
      " " + AppLocale.deleteCategoryConfirmationMessageSuffix.getString(context), // Added space
      () async {
        Navigator.of(context).pop();

        _customCategories.removeWhere((TodoCategory cat) => cat.name.toLowerCase() == categoryToDelete.name.toLowerCase());
        for (var item in items) {
          if (item.category == categoryToDelete.name) {
            item.category = null;
          }
        }
        await EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
        if (myCurrentUser != null) {
          myCurrentUser!.categories!.removeWhere((TodoCategory cat) => cat.name.toLowerCase() == categoryToDelete.name.toLowerCase());
          await FirebaseRepoInteractor.instance.updateUserData(myCurrentUser!);
        }
        _updateList();
        await _initializeTabs().then((_) {
          if (mounted && _tabController != null && _tabController!.length > 0) {
              _tabController!.animateTo(0);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocale.categoryDeletedSnackbar.getString(context).replaceAll('{categoryName}', categoryToDelete.name)),
        ));
      },
      () {
        Navigator.of(context).pop();
      },
      okBtnTxt: AppLocale.delete.getString(context),
      okColor: Colors.red,
    );
  }

  Future<int?> _selectCategoryColor(BuildContext dialogContext, TodoCategory currentCategoryInDialog) async { // Changed context name for clarity
    // final Map<String, Color> predefinedColors = { // String keys are for display if not localized
    //   "Red": Colors.red, "Green": Colors.green, "Blue": Colors.blue,
    //   "Yellow": Colors.yellow, "Purple": Colors.purple, "Orange": Colors.orange,
    //   "Pink": Colors.pink, "Brown": Colors.brown, "Teal": Colors.teal, "Cyan": Colors.cyan,
    //   "White": Colors.white, "Grey": Colors.grey,
    // };

    // Using AppLocale for tooltips
    final appLocale = AppLocale.of(dialogContext); // Get AppLocale instance
    final Map<int, String> colorTooltips = {
      Colors.red.value: appLocale.colorNameRed,
      Colors.green.value: appLocale.colorNameGreen,
      Colors.blue.value: appLocale.colorNameBlue,
      Colors.yellow.value: appLocale.colorNameYellow,
      Colors.purple.value: appLocale.colorNamePurple,
      Colors.orange.value: appLocale.colorNameOrange,
      Colors.pink.value: appLocale.colorNamePink,
      Colors.brown.value: appLocale.colorNameBrown,
      Colors.teal.value: appLocale.colorNameTeal,
      Colors.cyan.value: appLocale.colorNameCyan,
      Colors.white.value: appLocale.colorNameWhite,
      Colors.grey.value: appLocale.colorNameGrey,
    };
     final List<Color> predefinedColorsList = [
      Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple, Colors.orange,
      Colors.pink, Colors.brown, Colors.teal, Colors.cyan, Colors.white, Colors.grey,
    ];


    int? selectedColorValue = await showDialog<int>(
      context: dialogContext, // Use the passed dialogContext
      builder: (BuildContext colorDialogBuildContext) { // Different name for builder context
        return AlertDialog(
          title: Text(AppLocale.selectColorDialogTitle.getString(colorDialogBuildContext)),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: predefinedColorsList.map((Color color) { // Iterate over Color objects
                // final colorName = predefinedColors.entries.firstWhere((entry) => entry.value == color).key; // Original way to get English name
                final String tooltipText = colorTooltips[color.value] ?? color.toString(); // Fallback to hex string

                return GestureDetector(
                  onTap: () {
                    Navigator.of(colorDialogBuildContext).pop(color.value);
                  },
                  child: Tooltip(
                    message: tooltipText, // Use localized tooltip
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 20,
                      child: currentCategoryInDialog.color == color.value
                             ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white) // Contrast check for icon
                             : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocale.cancelButtonText.getString(colorDialogBuildContext)),
              onPressed: () {
                Navigator.of(colorDialogBuildContext).pop(null);
              },
            ),
          ],
        );
      },
    );
    return selectedColorValue;
  }

  String _loadRandomMotivational() {
    return motivationalKeys[Random().nextInt(
        motivationalKeys.length)];
  }
}

// Define a constant for the "Add New Category" option to avoid magic strings
const String kAddNewCategoryOption = 'add_new_category_option_val'; // Made it more unique