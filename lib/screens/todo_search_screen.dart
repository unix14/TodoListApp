import 'package:flutter/material.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/mixin/app_locale.dart'; // For AppLocale.getString
import 'package:flutter_localization/flutter_localization.dart'; // Added import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';


class TodoSearchScreen extends StatefulWidget {
  final List<TodoListItem> allItems;
  final List<String> categories; // All available category names
  final String initialCategory;  // The category that was active when search was initiated

  const TodoSearchScreen({
    Key? key,
    required this.allItems,
    required this.categories,
    required this.initialCategory,
  }) : super(key: key);

  @override
  State<TodoSearchScreen> createState() => _TodoSearchScreenState();
}

class _TodoSearchScreenState extends State<TodoSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = "";
  List<TodoListItem> _searchResults = [];
  int _totalSearchResultsCount = 0;

  // Placeholder for the actual header prefix, ensure it's defined if used.
  static const String HEADER_PREFIX = "HEADER::";


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
    _searchController.addListener(() {
      // Check if the controller's text actually changed from the last _searchQuery state
      // to prevent potential loops if _performSearch itself modifies the controller.
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _performSearch(_searchQuery);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Placeholder for the search logic method - to be fully implemented in Phase 2, Step 5
  void _performSearch(String query) {
    print("Search Screen: Performing search for: $query (Initial category: ${widget.initialCategory})");
    // Dummy logic for now, this will be replaced with the full search algorithm
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _totalSearchResultsCount = 0;
      });
      return;
    }
    // Basic filtering for stub, not the final logic
    _searchResults = widget.allItems.where((item) =>
        !item.isArchived && item.text.toLowerCase().contains(query.toLowerCase().trim())
    ).toList();
    _totalSearchResultsCount = _searchResults.length;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This is a basic structure. The full UI will be built in Phase 2, Step 4.
    return RawKeyboardListener(
      focusNode: FocusNode(), // Manage this focus node if needed for other parts
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            (kIsWeb || Theme.of(context).platform == TargetPlatform.windows || Theme.of(context).platform == TargetPlatform.linux || Theme.of(context).platform == TargetPlatform.macOS)) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: AppLocale.searchTodosHint.getString(context),
              border: InputBorder.none,
              hintStyle: TextStyle(
                 // Example: color: Theme.of(context).appBarTheme.toolbarTextStyle?.color?.withOpacity(0.7)
              ),
            ),
            // cursorColor: Example: Theme.of(context).appBarTheme.toolbarTextStyle?.color
            // style: Example: TextStyle(color: Theme.of(context).appBarTheme.toolbarTextStyle?.color)
            onChanged: (query){
                // Listener on controller already handles calling _performSearch
            }
          ),
          actions: [
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear),
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip, // Or a custom "Clear search" tooltip
                onPressed: () {
                  _searchController.clear();
                  // _performSearch is called by the listener.
                },
              ),
          ],
        ),
        body: _searchQuery.isEmpty && _searchResults.isEmpty
          ? Center(child: Text(AppLocale.enterSearchQuery.getString(context))) // Placeholder, needs new AppLocale key
          : _searchResults.isEmpty && _searchQuery.isNotEmpty
            ? Center(child: Text(AppLocale.noResultsFound.getString(context).replaceAll('{query}', _searchQuery)))
            : Column( // Basic structure for count + list
                children: [
                  if (_totalSearchResultsCount > 0)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(AppLocale.tasksFoundCount.getString(context).replaceAll('{count}', _totalSearchResultsCount.toString())),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        // This is a placeholder item display. The full logic with headers will be in Phase 2.
                        return ListTile(
                          title: Text(item.text),
                          subtitle: item.category != null ? Text(item.category!) : null,
                        );
                      },
                    ),
                  ),
                ],
              )
      ),
    );
  }
}

// Ensure AppLocale.enterSearchQuery is added to lib/mixin/app_locale.dart
// EN: "Enter a search term to begin."
// HE: "הזן מונח חיפוש כדי להתחיל."
// (This key will be formally added in a later step of the plan if not already present)
