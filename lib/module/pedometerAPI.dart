import 'package:flutter/material.dart';
import 'package:get/utils.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';

import '../data/keystring.dart';
import '../data/data_store.dart';

class PedometerAPI with WidgetsBindingObserver {
  static final PedometerAPI _instance = PedometerAPI._internal();
  factory PedometerAPI() => _instance;
  PedometerAPI._internal() {
    WidgetsBinding.instance.addObserver(this); // 앱 생명주기 관찰자 등록
    _initStream();
  }

  StreamSubscription<StepCount>? _stepCountSubscription;
  int _steps = 0;
  int get steps => _steps;

  void _initStream() {
    _stepCountSubscription?.cancel(); // 기존 구독 취소
    _stepCountSubscription = Pedometer.stepCountStream.listen(
          (event) {
            if(event.isNull) {
              _steps = 0;
            }else {
              _steps = event.steps;
            }
            DataStore().saveSharedPreferencesInt(Category().TOTALSTEP_KEY, _steps);
          },
      onError: (error) => print('Pedometer Stream Error: $error'),
      cancelOnError: true,
    );
  }
  // 외부에서 호출 가능한 메소드로 걸음수 데이터 새로고침 기능 제공
  void refreshSteps() {
    _initStream();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아오면 스트림을 재설정
      _initStream();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 관찰자 해제
    _stepCountSubscription?.cancel();
  }
}
