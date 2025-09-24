import 'package:flutter/material.dart';

/// Home 페이지의 비즈니스 로직을 담당하는 컨트롤러
class HomeController {
  final ValueNotifier<int> _counter = ValueNotifier<int>(0);

  /// 외부에서 카운터 값을 구독할 수 있는 notifier
  ValueNotifier<int> get counterNotifier => _counter;

  /// 현재 카운터 값
  int get counter => _counter.value;

  /// 컨트롤러 초기화
  void initialize() {
    _counter.value = 0;
  }

  /// 카운터 증가
  void incrementCounter() {
    _counter.value++;
  }

  /// 카운터 감소
  void decrementCounter() {
    if (_counter.value > 0) {
      _counter.value--;
    }
  }

  /// 카운터 초기화
  void resetCounter() {
    _counter.value = 0;
  }

  /// 카운터 특정 값으로 설정
  void setCounter(int value) {
    if (value >= 0) {
      _counter.value = value;
    }
  }

  /// 메모리 해제
  void dispose() {
    _counter.dispose();
  }
}