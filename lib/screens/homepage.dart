import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/common/DialogHelper.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/date_extensions.dart';
import 'package:flutter_example/common/dialog_extensions.dart';
import 'package:flutter_example/common/encrypted_shared_preferences_helper.dart';
import 'package:flutter_example/common/globals.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_example/common/home_widget_helper.dart';
import 'package:flutter_example/common/stub_data.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/mixin/pwa_installer_mixin.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_example/models/user.dart' as MyUser;
import 'package:flutter_example/screens/onboarding.dart';
import 'package:flutter_example/screens/settings.dart';
// import 'package:flutter_example/screens/todo_search_screen.dart'; // Removed as file is deleted
import 'package:flutter_example/widgets/rounded_text_input_field.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:home_widget/home_widget.dart';

import 'onboarding.dart';

const String kRenameCategoryMenuButtonName = 'rename_category';
const String kDeleteCategoryMenuButtonName = 'delete_category';
const String kShareCategoryMenuButtonName = 'share_category';

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
  Map<String, String> _sharedCategorySlugs = {};
  final Map<String, StreamSubscription<DatabaseEvent>> _sharedListSubscriptions = {};
  bool _incomingSlugHandled = false;
  bool _isPromptingForCategory = false;

  // Search state
  bool _isSearching = false;
  String _searchQuery = "";
  late FocusNode _searchFocusNode;
  late TextEditingController _searchController;
  List<TodoListItem> _searchResults = []; // Initialize search results list
  static const String HEADER_PREFIX = "HEADER::";


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
    _checkIncomingSharedSlug();
    Future.delayed(Duration.zero, () {
      myBanner?.load();
    });
  }
  Future<void> _checkIncomingSharedSlug() async {
    if (_incomingSlugHandled) return;
    if (incomingSharedSlug != null && currentUser != null) {
      final data = await FirebaseRepoInteractor.instance
          .getSharedCategoryData(incomingSharedSlug!);
      if (data.isNotEmpty) {
        String name = data['name'] ?? '';
        Map<String, dynamic> members =
            Map<String, dynamic>.from(data['members'] ?? {});
        bool alreadyMember = members.containsKey(currentUser!.uid);
        bool proceed = alreadyMember;

        if (!alreadyMember) {
          String ownerUid = data['owner'] ?? '';
          final owner = await FirebaseRepoInteractor.instance.getUserData(ownerUid);
          bool? accepted = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text(AppLocale.invitationTitle.getString(dialogContext)),
                content: Text(
                  AppLocale.invitationMessage
                      .getString(dialogContext)
                      .replaceAll('{user}', (owner?.name?.isNotEmpty ?? false) ? owner!.name! : AppLocale.anonymous.getString(dialogContext))
                      .replaceAll('{email}', owner?.email ?? ''),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(AppLocale.decline.getString(dialogContext)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(AppLocale.accept.getString(dialogContext)),
                  ),
                ],
              );
            },
          );
          proceed = accepted == true;
        }

        if (proceed) {
          bool added = false;
          if (!_customCategories.contains(name)) {
            _customCategories.add(name);
            await EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
            added = true;
          }
          _sharedCategorySlugs[name] = incomingSharedSlug!;
          await EncryptedSharedPreferencesHelper.saveSharedSlugs(_sharedCategorySlugs);

          if (!members.containsKey(currentUser!.uid)) {
            members[currentUser!.uid] = true;
            try {
              final success = await FirebaseRepoInteractor.instance
                  .saveSharedCategoryData(
                incomingSharedSlug!,
                {
                  ...data,
                  'members': members,
                },
              );
              if (!success && mounted) {
                context
                    .showSnackBar(AppLocale.shareFailed.getString(context));
              }
            } catch (e) {
              if (mounted) {
                context
                    .showSnackBar(AppLocale.shareFailed.getString(context));
              }
            }
          }

          if (added && mounted) {
            await _initializeTabs();
            final index = _categories.indexOf(name);
            setState(() {
              if (index != -1 && _tabController != null) {
                _tabController!.index = index;
              }
            });
          }
        }
      }
      incomingSharedSlug = null;
      _incomingSlugHandled = true;
    } else {
      _incomingSlugHandled = true;
    }
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
    _sharedCategorySlugs = await EncryptedSharedPreferencesHelper.loadSharedSlugs();

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
    if (previousIndex >
        newCategories.length) { // If it's beyond the '+' tab index
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
      _startSharedListeners();
    } else {
      // If not mounted, dispose the newly created controller to avoid leaks
      newTabController.dispose();
    }
  }

  void _startSharedListeners() {
    _cancelSharedListeners();
    for (var entry in _sharedCategorySlugs.entries) {
      _listenToSharedList(entry.key, entry.value);
    }
  }

  void _listenToSharedList(String categoryName, String slug) {
    final ref = FirebaseDatabase.instance.ref('sharedLists/$slug/items');
    final sub = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final newItems = data.values
            .whereType<Map>()
            .map((e) {
              final item = TodoListItem.fromJson(
                  Map<String, dynamic>.from(e as Map));
              item.category = categoryName;
              return item;
            })
            .toList();
        setState(() {
          items.removeWhere((i) => i.category == categoryName);
          items.addAll(newItems);
        });
        _updateList(fromRemote: true);
      }
    });
    _sharedListSubscriptions[categoryName] = sub;
  }

  void _cancelSharedListeners() {
    for (var sub in _sharedListSubscriptions.values) {
      sub.cancel();
    }
    _sharedListSubscriptions.clear();
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
    _cancelSharedListeners();
    myBanner?.dispose();
    _todoLineFocusNode.dispose(); // Dispose of the FocusNode
    _textEditingController.dispose(); // Dispose the text controller
    _searchFocusNode.dispose();
    _searchController.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_onKey);
    super.dispose();
  }

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
    // _initializeTabs will be called from didChangeDependencies
    ServicesBinding.instance.keyboard.addHandler(_onKey);
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
    if (_tabController!.index < 0 ||
        _tabController!.index >= _categories.length) {
      return false;
    }
    // Check if the selected category is NOT the "All" category.
    return _categories[_tabController!.index] !=
        AppLocale.all.getString(context);
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
    final List<String> motivationalKeys = [
      AppLocale.motivationalSentence1,
      AppLocale.motivationalSentence2,
      AppLocale.motivationalSentence3,
      AppLocale.motivationalSentence4,
      AppLocale.motivationalSentence5,
    ];
    final randomKey = motivationalKeys[Random().nextInt(
        motivationalKeys.length)];

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
              tabs: [
                ..._categories
                    .map((String name) =>
                    Tab(
                      text: name.substring(0, min(name.length,
                          MAX_CHARS_IN_TAB_BAR)) +
                          (name.length > MAX_CHARS_IN_TAB_BAR ? "..." : ""),
                    )
                )
                    .toList(),
                Tab(
                    icon: Tooltip(
                        message: AppLocale.addCategoryTooltip.getString(
                            context),
                        child: const Icon(Icons.add))),
              ],
            ),
          ),
        ),
        leading: _isSearching ? null : IconButton(
          icon: const Icon(Icons.shuffle,),
          onPressed: _showRandomTask, // Call renamed method
          tooltip: AppLocale.randomTaskMenuButton.getString(context),
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
        ]
            : _buildDefaultAppBarActions(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: _tabController == null || _categories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: List<Widget>.generate(
                  _tabController?.length ?? 0, // Ensure controller is not null
                      (index) {
                    if (_tabController == null || index >= _categories.length) {
                      // This is for the "+" tab, or if controller is null initially
                      return Container(); // Empty view for the action tab
                    }
                    // Actual category view
                    final currentCategoryNameForTab = _categories[index]; // Renamed for clarity

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
                          if (currentCategoryNameForTab ==
                              AppLocale.all.getString(context)) {
                            itemsToDisplayOrSearchIn = allLoadedItems.reversed
                                .where((item) => !item.isArchived)
                                .toList();
                          } else {
                            itemsToDisplayOrSearchIn = allLoadedItems.reversed
                                .where((item) =>
                            !item.isArchived &&
                                item.category == currentCategoryNameForTab)
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
                                      randomKey.getString(context),
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
                                listContent = Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 16.0),
                                      child: Text(taskCountString,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 13.0,
                                              color: Colors.blueGrey,
                                              fontWeight: FontWeight.w500)),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: itemsToDisplayOrSearchIn
                                            .length,
                                        itemBuilder: (context, itemIndex) =>
                                            getListTile(
                                                itemsToDisplayOrSearchIn[itemIndex]),
                                      ),
                                    ),
                                  ],
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
                                    if (rawHeaderText.startsWith(
                                        AppLocale.resultsInCategory + "::")) {
                                      String catName = rawHeaderText.substring(
                                          (AppLocale.resultsInCategory + "::")
                                              .length);
                                      displayHeaderText =
                                          AppLocale.resultsInCategory.getString(
                                              context).replaceAll(
                                              '{categoryName}', catName);
                                    } else {
                                      // Fallback for safety or if other header types were introduced in the future.
                                      // Given current _performSearch logic (after removing specific uncategorized header),
                                      // this branch should ideally not be hit for distinct headers other than 'resultsInCategory'.
                                      displayHeaderText =
                                          rawHeaderText.replaceAll("::", " ");
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
                            if (currentCategoryNameForTab ==
                                AppLocale.all.getString(context) &&
                                itemsToDisplayOrSearchIn.isEmpty) {
                              final List<String> motivationalKeys = [
                                AppLocale.motivationalSentence1,
                                AppLocale.motivationalSentence2,
                                AppLocale.motivationalSentence3,
                                AppLocale.motivationalSentence4,
                                AppLocale.motivationalSentence5,
                              ];
                              final randomKey = motivationalKeys[Random()
                                  .nextInt(motivationalKeys.length)];
                              listContent = Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    randomKey.getString(context),
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
                              listContent = Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    child: Text(taskCountString,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13.0,
                                            color: Colors.blueGrey,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: itemsToDisplayOrSearchIn
                                          .length,
                                      itemBuilder: (context, itemIndex) =>
                                          getListTile(
                                              itemsToDisplayOrSearchIn[itemIndex]),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              listContent = Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    randomKey.getString(context),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ); // Empty list view for non-"All" categories that are empty
                            }
                          }
                          return Column(
                            children: [
                              _buildMembersRow(currentCategoryNameForTab),
                              Expanded(child: listContent),
                            ],
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
          AppLocale.emptyTodoDialogTitle.getString(context),
          AppLocale.emptyTodoDialogMessage.getString(context),
              () {
            // Ok
            Navigator.of(context).pop(); // dismiss dialog
          }, null);
    }
  }

  void _updateList({bool fromRemote = false}) async {
    // Convert the current list to JSON
    var listAsStr = jsonEncode(items);
    await EncryptedSharedPreferencesHelper.setString(
        kAllListSavedPrefs, listAsStr);
    print("update list :" + listAsStr);

    // todo update realtime DB if logged in

    if (!fromRemote && isLoggedIn && currentUser?.uid.isNotEmpty == true) {
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
      for (var entry in _sharedCategorySlugs.entries) {
        final catItems = items.where((i) => i.category == entry.key).toList();
        await FirebaseRepoInteractor.instance.saveSharedCategoryItems(entry.value, catItems);
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

          var list = myCurrentUser!.todoListItems!;
          for (var entry in _sharedCategorySlugs.entries) {
            final sharedItems = await FirebaseRepoInteractor.instance.getSharedCategoryItems(entry.value);
            for (var item in sharedItems) {
              item.category = entry.key;
              if (!list.any((e) => e.text == item.text && e.category == item.category)) {
                list.add(item);
              }
            }
          }
          return list;
        }
      }
      for (var entry in _sharedCategorySlugs.entries) {
        final sharedItems = await FirebaseRepoInteractor.instance.getSharedCategoryItems(entry.value);
        for (var item in sharedItems) {
          item.category = entry.key;
          if (!sharedPrefsTodoList.any((e) => e.text == item.text && e.category == item.category)) {
            sharedPrefsTodoList.add(item);
          }
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
        var list = myCurrentUser!.todoListItems!;
        for (var entry in _sharedCategorySlugs.entries) {
          final sharedItems = await FirebaseRepoInteractor.instance.getSharedCategoryItems(entry.value);
          for (var item in sharedItems) {
            item.category = entry.key;
            if (!list.any((e) => e.text == item.text && e.category == item.category)) {
              list.add(item);
            }
          }
        }
        return list;
      }
      var list = StubData.getInitialTodoList(context);
      for (var entry in _sharedCategorySlugs.entries) {
        final sharedItems = await FirebaseRepoInteractor.instance.getSharedCategoryItems(entry.value);
        for (var item in sharedItems) {
          item.category = entry.key;
          if (!list.any((e) => e.text == item.text && e.category == item.category)) {
            list.add(item);
          }
        }
      }
      return list;
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
                      cursorColor: Theme.of(context).colorScheme.primary,
                      decoration: InputDecoration(
                        hintText: AppLocale.categoryNameHintText.getString(dialogContext),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
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
          updateHomeWidget();
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
        AppLocale.doUwant2Delete.getString(context), // Assuming this key exists
        AppLocale.thisCantBeUndone.getString(context), // Assuming this key exists
        () {
      Navigator.of(context).pop(); // dismiss confirmation dialog
      _setEditingTodo(null); // Exit edit mode if the item being deleted was in edit mode
      setState(() {
        items.remove(todoItem);
        // if (itemOnEditIndex >= items.length) { // Adjust if delete was last item // Removed
        //   itemOnEditIndex = -1;
        // } else if (items.isNotEmpty && itemOnEditIndex != -1 && items[itemOnEditIndex] == todoItem) {
        //    // If the deleted item was the one being edited.
        //    itemOnEditIndex = -1;
        // }
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
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, kAddNewCategoryOption); // Special value for "Add New"
              },
              // Assuming AppLocale.addNewCategoryMenuItem will be added to your localization files
              // For now, using a placeholder string or you can add it to AppLocale.dart
              child: Text(AppLocale.addNewCategoryMenuItem.getString(dialogContext)),
            ),
          ],
        );
      },
    ).then((selectedCategoryNameOrAction) {
      if (selectedCategoryNameOrAction == kAddNewCategoryOption) {
        // User selected "Add New Category"
        _promptForNewCategory().then((newlyCreatedCategoryName) {
          if (newlyCreatedCategoryName != null && newlyCreatedCategoryName.isNotEmpty) {
            // New category was created
            setState(() {
              todoItem.category = newlyCreatedCategoryName;
              _updateList(); // Save the change
            });
            _initializeTabs(); // Refresh tab bar, this will re-initialize tabs and controller

            // Show SnackBar confirmation
            final snackBar = SnackBar(
              content: Text(
                AppLocale.itemMovedSnackbar.getString(context).replaceAll('{categoryName}', newlyCreatedCategoryName),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
          // If newlyCreatedCategoryName is null, user cancelled creation, do nothing further.
        });
      } else {
        // User selected an existing category or "Uncategorized"
        final selectedCategoryName = selectedCategoryNameOrAction as String?; // Cast to String? as it can be null

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
                          return AppLocale.categoryNameExistsError.getString(dialogContext); // Or a more specific error
                        }
                        // Check against _customCategories for uniqueness,
                        // unless it's the original name (allowing case changes)
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
                  Navigator.of(dialogContext).pop(null); // Dialog returns null
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
        // If a new valid name was returned and it's different from the old one
        setState(() {
          final oldNameIndex = _customCategories.indexWhere((cat) => cat.toLowerCase() == oldCategoryName.toLowerCase());
          if (oldNameIndex != -1) {
            _customCategories[oldNameIndex] = newCategoryName!;
          }

          // Update items
          for (var item in items) {
            if (item.category == oldCategoryName) {
              item.category = newCategoryName;
            }
          }

          EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
          updateHomeWidget();
          print('[HomeWidget] Sent update request to widget provider after renaming category.');
          _updateList(); // Persist item changes
          _initializeTabs(); // Refresh UI

          // Show SnackBar
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
        // Name is the same (possibly different case, but validation passes this)
        // We still might want to update if the casing changed and categories are case-sensitive in storage
        // For this implementation, if only casing changed, we effectively treat it as "no change" for persistence,
        // but we return the potentially case-changed newCategoryName.
        // If strict case persistence is needed, _customCategories and item.category should be updated.
        // For now, we assume the main goal is achieved if the name (ignoring case for comparison) is "the same".
      }
      return newCategoryName; // Return the new name or null if cancelled

    } catch (e) {
      // Handle any errors during the process
      print("Error in _promptRenameCategory: $e");
      return null;
    }
  }

  Future<void> _showShareDialog(String categoryName) async {
    String slug;
    if (_sharedCategorySlugs.containsKey(categoryName)) {
      slug = _sharedCategorySlugs[categoryName]!;
    } else {
      slug = await FirebaseRepoInteractor.instance.generateUniqueSlug(categoryName);
      try {
        final success = await FirebaseRepoInteractor.instance.saveSharedCategoryData(
          slug,
          {
            'name': categoryName,
            'owner': currentUser?.uid,
            'created': DateTime.now().toIso8601String(),
            'members': {if (currentUser != null) currentUser!.uid: true},
          },
        );
        if (!success) {
          context.showSnackBar(AppLocale.shareFailed.getString(context));
          return;
        }
        _sharedCategorySlugs[categoryName] = slug;
        await EncryptedSharedPreferencesHelper.saveSharedSlugs(_sharedCategorySlugs);
      } catch (e) {
        context.showSnackBar(AppLocale.shareFailed.getString(context));
        return;
      }
    }

    final data = await FirebaseRepoInteractor.instance.getSharedCategoryData(slug);
    Map<String, dynamic> members = Map<String, dynamic>.from(data['members'] ?? {});
    String created = data['created'] ?? '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocale.shareCategory.getString(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppLocale.createdOn.getString(context).replaceAll('{date}', created.split('T').first)}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(kShareBaseUrl + slug)),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: AppLocale.copyLink.getString(context),
                    onPressed: () => context.copyToClipboard(kShareBaseUrl + slug),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (members.isNotEmpty)
                Text(AppLocale.sharedWith.getString(context)),
                if (members.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Wrap(
                      spacing: 4.0,
                      children: [
                        for (var uid in members.keys.take(2))
                          FutureBuilder<MyUser.User?>(
                            future: FirebaseRepoInteractor.instance.getUserData(uid),
                            builder: (context, snapshot) {
                              Widget avatar;
                              if (snapshot.hasData && snapshot.data!.imageURL != null && snapshot.data!.imageURL!.isNotEmpty) {
                                try {
                                  avatar = CircleAvatar(
                                    radius: 16,
                                    backgroundImage: MemoryImage(base64Decode(snapshot.data!.imageURL!)),
                                  );
                                } catch (_) {
                                  avatar = const CircleAvatar(radius: 16, child: Icon(Icons.person));
                                }
                              } else {
                                final initials = (snapshot.data?.name ?? '').isNotEmpty
                                    ? snapshot.data!.name!.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                                    : '';
                                if (initials.isEmpty) {
                                  avatar = const CircleAvatar(radius: 16, child: Icon(Icons.person));
                                } else {
                                  avatar = CircleAvatar(radius: 16, child: Text(initials));
                                }
                              }
                              final tooltip = '${snapshot.data?.name?.isNotEmpty == true ? snapshot.data!.name! : AppLocale.anonymous.getString(context)}\n${snapshot.data?.email ?? ''}';
                              return Tooltip(message: tooltip, child: avatar);
                            },
                          ),
                        if (members.keys.length > 2)
                          CircleAvatar(
                            radius: 16,
                            child: Text('+${members.keys.length - 2}'),
                          ),
                      ],
                    ),
                  ),
              if (currentUser != null && currentUser!.uid == data['owner'])
                Column(
                  children: members.keys
                      .where((uid) => uid != currentUser!.uid)
                      .map((uid) => FutureBuilder<MyUser.User?>(
                            future: FirebaseRepoInteractor.instance.getUserData(uid),
                            builder: (context, snap) {
                              final name = snap.data?.name ?? uid;
                              return ListTile(
                                title: Text(name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  onPressed: () async {
                                    members.remove(uid);
                                    try {
                                      final success = await FirebaseRepoInteractor.instance.saveSharedCategoryData(
                                        slug,
                                        {
                                          ...data,
                                          'members': members,
                                        },
                                      );
                                      if (!success && mounted) {
                                        context.showSnackBar(AppLocale.shareFailed.getString(context));
                                        return;
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        context.showSnackBar(AppLocale.shareFailed.getString(context));
                                      }
                                      return;
                                    }
                                    Navigator.of(dialogContext).pop();
                                    _showShareDialog(categoryName);
                                  },
                                ),
                              );
                            },
                          ))
                      .toList(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocale.ok.getString(context)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMembersRow(String categoryName) {
    final slug = _sharedCategorySlugs[categoryName];
    if (slug == null) return const SizedBox.shrink();
    return FutureBuilder<Map<String, dynamic>>(
      future: FirebaseRepoInteractor.instance.getSharedCategoryData(slug),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final membersMap = Map<String, dynamic>.from(snapshot.data!['members'] ?? {});
        membersMap.remove(currentUser?.uid);
        final uids = membersMap.keys.toList();
        if (uids.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              for (var uid in uids.take(2))
                FutureBuilder<MyUser.User?>(
                  future: FirebaseRepoInteractor.instance.getUserData(uid),
                  builder: (context, snapshot) {
                    Widget avatar;
                    if (snapshot.hasData && snapshot.data!.imageURL != null && snapshot.data!.imageURL!.isNotEmpty) {
                      try {
                        avatar = CircleAvatar(
                          radius: 12,
                          backgroundImage: MemoryImage(base64Decode(snapshot.data!.imageURL!)),
                        );
                      } catch (_) {
                        avatar = const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12));
                      }
                    } else {
                      final initials = (snapshot.data?.name ?? '').isNotEmpty
                          ? snapshot.data!.name!.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                          : '';
                      if (initials.isEmpty) {
                        avatar = const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12));
                      } else {
                        avatar = CircleAvatar(radius: 12, child: Text(initials, style: const TextStyle(fontSize: 10)));
                      }
                    }
                    final tooltip = '${snapshot.data?.name?.isNotEmpty == true ? snapshot.data!.name! : AppLocale.anonymous.getString(context)}\n${snapshot.data?.email ?? ''}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Tooltip(message: tooltip, child: avatar),
                    );
                  },
                ),
              if (uids.length > 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: CircleAvatar(
                    radius: 12,
                    child: Text('+${uids.length - 2}', style: const TextStyle(fontSize: 10)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Renamed existing method to avoid conflict
  void _toggleSearchUI() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        // Request focus after the frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchQuery = "";
        _searchController.clear();
        _searchResults = []; // Clear search results when exiting search mode
      }
    });
    _performSearch(_searchQuery); // Call perform search even when exiting to potentially clear/reset list
    // Keep a distinct debug print for the original functionality if needed for testing
    debugPrint("Toggle Search UI: _isSearching is now $_isSearching");
  }

  void _performSearch(String query) {
    final String lowerCaseQuery = query.toLowerCase().trim();
    List<TodoListItem> newResults = [];

    if (!_isSearching || lowerCaseQuery.isEmpty) {
      // If not searching or query is empty, results should be empty or reflect current category (handled by main builder)
      // However, specifically for _performSearch, if query is empty, clear _searchResults
       setState(() {
        _searchResults = [];
      });
      return;
    }

    final String currentCategoryName = _tabController != null && _tabController!.index < _categories.length
        ? _categories[_tabController!.index]
        : AppLocale.all.getString(context);
    final bool isAllTab = false;//currentCategoryName == AppLocale.all.getString(context);

    if (isAllTab) {
      newResults = items
          .where((item) =>
              !item.isArchived &&
              item.text.toLowerCase().contains(lowerCaseQuery))
          .toList();
    } else {
      // Search in current category first
      // final List<TodoListItem> currentCategoryMatches = items
          // .where((item) =>
          //     !item.isArchived &&
          //     item.category == currentCategoryName &&
          //     item.text.toLowerCase().contains(lowerCaseQuery))
          // .toList();
      // newResults.addAll(currentCategoryMatches);

      // Search in other categories
      for (String otherCategory in _categories) {
        // if (otherCategory == currentCategoryName) {// || otherCategory == AppLocale.all.getString(context)) {
        //   continue; // Skip current and "All" tab
        // }
        final List<TodoListItem> otherCategoryMatches = items
            .where((item) =>
                !item.isArchived &&
                item.category == otherCategory && // Make sure item.category can be null for "Uncategorized"
                item.text.toLowerCase().contains(lowerCaseQuery))
            .toList();

        if (otherCategoryMatches.isNotEmpty) {
          // Add header for this category
          // Store AppLocale keys for headers
          newResults.add(TodoListItem("$HEADER_PREFIX${AppLocale.resultsInCategory}::$otherCategory", category: otherCategory));
          newResults.addAll(otherCategoryMatches);
        }
      }
       // Also search for items that are uncategorized if current tab isn't "All"
      // and add them directly without a header.
      if (!isAllTab) {
        final List<TodoListItem> uncategorizedMatches = items
            .where((item) =>
                !item.isArchived &&
                item.category == null && // Uncategorized items
                item.text.toLowerCase().contains(lowerCaseQuery))
            .toList();
        if (uncategorizedMatches.isNotEmpty) {
          // Add uncategorized matches directly with a header
          newResults.add(TodoListItem("$HEADER_PREFIX${AppLocale.resultsInAllCategory.getString(context)}", category: null));
          newResults.addAll(uncategorizedMatches);
        }
      }
    }

    setState(() {
      _searchResults = newResults;
    });
    debugPrint("Performing search for: $query. Found ${_searchResults.length} results.");
  }

  /// Default actions for the app bar.
  ///
  /// Returns a search button and a popup menu with various actions.
  List<Widget> _buildDefaultAppBarActions(BuildContext context) {
    final searchButton = IconButton(
      icon: const Icon(Icons.search),
      onPressed: _toggleSearchUI,
      tooltip: AppLocale.searchTodosTooltip.getString(context),
    );

    final menuButton = PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case kInstallMenuButtonName:
            showInstallPrompt();
            context.showSnackBar(AppLocale.appIsInstalled.getString(context));
            break;
          case kArchiveMenuButtonName:
            showArchivedTodos();
            break;
          case kLoginButtonMenu:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
            break;
          case kSettingsMenuButtonName:
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            if (result == true && mounted) {
              setState(() {
                _loadingData = loadList();
              });
              await _initializeTabs();
              if (mounted && _tabController != null && _tabController!.length > 0) {
                _tabController!.animateTo(0);
              }
            }
            break;
          case kRenameCategoryMenuButtonName:
            if (_isCurrentCategoryCustom()) {
              final currentCategoryName = _categories[_tabController!.index];
              _promptRenameCategory(currentCategoryName);
            }
            break;
          case kDeleteCategoryMenuButtonName:
            if (_isCurrentCategoryCustom()) {
              final currentCategoryName = _categories[_tabController!.index];
              DialogHelper.showAlertDialog(
                context,
                AppLocale.deleteCategoryConfirmationTitle.getString(context),
                AppLocale.deleteCategoryConfirmationMessage
                    .getString(context)
                    .replaceAll('{categoryName}', currentCategoryName),
                () {
                  Navigator.of(context).pop();
                  setState(() {
                    _customCategories.removeWhere(
                        (cat) => cat.toLowerCase() == currentCategoryName.toLowerCase());
                    for (var item in items) {
                      if (item.category == currentCategoryName) {
                        item.category = null;
                      }
                    }
                    EncryptedSharedPreferencesHelper.saveCategories(_customCategories);
                    updateHomeWidget();
                    print('[HomeWidget] Sent update request to widget provider after deleting category.');
                    _updateList();
                    _initializeTabs().then((_) {
                      if (mounted && _tabController != null) {
                        _tabController!.index = 0;
                      }
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocale.categoryDeletedSnackbar
                            .getString(context)
                            .replaceAll('{categoryName}', currentCategoryName),
                      ),
                    ),
                  );
                },
                () {
                  Navigator.of(context).pop();
                },
              );
            }
            break;
          case kShareCategoryMenuButtonName:
            if (_isCurrentCategoryCustom()) {
              final currentCategoryName = _categories[_tabController!.index];
              _showShareDialog(currentCategoryName);
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        final itemsList = <PopupMenuEntry<String>>[];

        if (!isLoggedIn) {
          itemsList.add(
            PopupMenuItem<String>(
              value: kLoginButtonMenu,
              child: Row(
                children: [
                  const Icon(Icons.supervised_user_circle, color: Colors.blue),
                  const SizedBox(width: 8.0),
                  Text(AppLocale.login.getString(context)),
                ],
              ),
            ),
          );
        }

        if (isInstallable()) {
          itemsList.add(
            PopupMenuItem<String>(
              value: kInstallMenuButtonName,
              child: Row(
                children: [
                  const Icon(Icons.install_mobile, color: Colors.blue),
                  const SizedBox(width: 8.0),
                  Text(AppLocale.installApp.getString(context)),
                ],
              ),
            ),
          );
        }

        if (items.any((item) => item.isArchived)) {
          itemsList.add(
            PopupMenuItem<String>(
              value: kArchiveMenuButtonName,
              child: Row(
                children: [
                  const Icon(Icons.archive, color: Colors.blue),
                  const SizedBox(width: 8.0),
                  Text(AppLocale.archive.getString(context)),
                ],
              ),
            ),
          );
        }

        if (_isCurrentCategoryCustom()) {
          itemsList.add(
            PopupMenuItem<String>(
              value: kRenameCategoryMenuButtonName,
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue),
                  const SizedBox(width: 8.0),
                  Text(AppLocale.renameCategoryMenuButton.getString(context)),
                ],
              ),
            ),
          );
          itemsList.add(
            PopupMenuItem<String>(
              value: kDeleteCategoryMenuButtonName,
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.red),
                  const SizedBox(width: 8.0),
                  Text(
                    AppLocale.deleteCategoryMenuButton.getString(context),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
          itemsList.add(
            PopupMenuItem<String>(
              value: kShareCategoryMenuButtonName,
              child: Row(
                children: [
                  const Icon(Icons.share, color: Colors.blue),
                  const SizedBox(width: 8.0),
                  Text(AppLocale.shareCategory.getString(context)),
                ],
              ),
            ),
          );
        }

        itemsList.add(
          PopupMenuItem<String>(
            value: kSettingsMenuButtonName,
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, color: Colors.blue),
                const SizedBox(width: 8.0),
                Text(AppLocale.settings.getString(context)),
              ],
            ),
          ),
        );

        return itemsList;
      },
    );

    return [searchButton, menuButton];
  }
}

// Define a constant for the "Add New Category" option to avoid magic strings
const String kAddNewCategoryOption = 'add_new_category_option_val'; // Made it more unique

