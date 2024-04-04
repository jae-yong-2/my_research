import 'package:health/health.dart';

class HealthKit {
  HealthFactory health = HealthFactory();

  Future<int> getSteps() async {
    List<HealthDataType> types = [HealthDataType.STEPS];
    bool accessGranted = await health.requestAuthorization(types);
    int steps = 0;
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime endDate = DateTime.now();

    if (accessGranted) {
      try {
        List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(startDate, endDate, types);
        steps = healthData.where((dataPoint) => dataPoint.type == HealthDataType.STEPS).fold(0, (sum, dataPoint) {
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