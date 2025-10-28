import 'package:flutter/material.dart';

class NotificationService with ChangeNotifier {
  int _count = 5;

  int get count => _count;

  void decrement() {
    if (_count > 0) {
      _count--;
      notifyListeners();
    }
  }

  void reset() {
    _count = 5;
    notifyListeners();
  }

  void setCount(int newCount) {
    _count = newCount;
    notifyListeners();
  }
}
