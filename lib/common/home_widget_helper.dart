import "dart:async";
import 'package:home_widget/home_widget.dart';

Future<void> updateHomeWidget() async {
  try {
    // Notify the widget to update
    await HomeWidget.updateWidget(
      name: 'com.eyalya94.tools.todoLater.TodoWidgetProvider',
      iOSName: 'TodoWidgetProvider',
    );
  } catch(e) {
    print("Failed to updateHomeWidget: " + e.toString());
  }
}
