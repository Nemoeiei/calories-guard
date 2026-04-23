// Pure model tests — no runtime deps.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/goal_option.dart';

void main() {
  group('GoalOption enum', () {
    test('has three options', () {
      expect(GoalOption.values.length, 3);
    });

    test('contains loseWeight / maintainWeight / buildMuscle', () {
      expect(GoalOption.values, contains(GoalOption.loseWeight));
      expect(GoalOption.values, contains(GoalOption.maintainWeight));
      expect(GoalOption.values, contains(GoalOption.buildMuscle));
    });
  });
}
