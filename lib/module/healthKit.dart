import 'package:health/health.dart';

class HealthKit {

  HealthFactory health = HealthFactory();

  // 걸음수를 가져오는 함수
  Future<int> getSteps() async {
    // 초기화
    List<HealthDataType> types = [HealthDataType.STEPS];
    bool accessGranted = await health.requestAuthorization(types);
    int steps = 0;
    DateTime now = DateTime.now();
    // 오늘 정오를 나타냄
    DateTime startDate = DateTime(now.year, now.month, now.day, 12, 0, 0);
    // 현재 시간을 나타냄
    DateTime endDate = DateTime.now();

    if (accessGranted) {
      try {
        // 걸음수 데이터 가져오기
        // 걸음수 데이터 가져오기
        List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(startDate, endDate, types);

// 데이터 포인트를 직접 순회하여 총 걸음수 계산
        steps = healthData
            .where((dataPoint) => dataPoint.type == HealthDataType.STEPS)
            .fold(0, (sum, dataPoint) {
          // value가 double 타입인 경우를 대비하여 round 처리
          var value = (dataPoint.value is int) ? dataPoint.value : (int.parse(dataPoint.value.toString()));
          return sum + (value as int);
        });

      } catch (exception) {
        print(exception.toString());
      }
    }
    return steps;
  }
}
