import 'package:flutter_test/flutter_test.dart';
import 'package:servisku/models/models.dart';

void main() {
  test('Reminder due date per month', () {
    final r = ServiceReminder(
      id: 'x',
      vehicleId: 'v',
      title: 'Oli',
      category: 'oli',
      mode: IntervalMode.month,
      intervalMonths: 2,
      intervalKm: 2000,
      lastServiceDate: DateTime(2025, 1, 10),
      lastServiceKm: 1000,
      notifyDaysBefore: 7,
      notifyKmBefore: 200,
      active: true,
      notes: '',
      createdAt: DateTime(2025, 1, 10),
    );
    expect(r.dueDate!.month, 3);
    expect(r.dueKm, isNull);
  });
}
