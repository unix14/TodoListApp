import 'package:flutter/cupertino.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_localization/flutter_localization.dart';


class StubData {
  static List<TodoListItem> getInitialTodoList(BuildContext context) {
    List<TodoListItem> list = [];
    list.add(TodoListItem(AppLocale.todoExample1.getString(context)));
    list.add(TodoListItem(AppLocale.todoExample2.getString(context)));
    list.add(TodoListItem(AppLocale.todoExample3.getString(context)));
    return list;
  }
}
