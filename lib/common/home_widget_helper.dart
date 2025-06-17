import 'package:home_widget/home_widget.dart';

void updateHomeWidget() {
  try {
    // Notify the widget to update
    HomeWidget.updateWidget(
      name: 'com.eyalya94.tools.todoLater.TodoWidgetProvider',
      iOSName: 'TodoWidgetProvider',
    );
  } catch(e) {
    print("Failed to updateHomeWidget" + e.toString());
  }
}
