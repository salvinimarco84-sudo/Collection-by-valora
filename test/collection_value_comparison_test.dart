import 'package:flutter_test/flutter_test.dart';
import 'package:collection_by_valora/main.dart';

void main() {
  group('calculateCollectionValueComparison', () {
    test('compares only identical objects and applies the same quantities', () {
      final result = calculateCollectionValueComparison(
        currentValues: {'1': 100, '2': 40, '3': 12},
        previousValues: {'1': 80, '3': 15, '4': 900},
        quantities: {'1': 2, '2': 1, '3': 3},
      );

      expect(result.comparedObjects, 2);
      expect(result.currentTotal, 236);
      expect(result.previousTotal, 205);
      expect(result.difference, 31);
    });

    test('reports no comparable objects when periods do not overlap', () {
      final result = calculateCollectionValueComparison(
        currentValues: {'1': 25},
        previousValues: {'2': 20},
        quantities: {'1': 4},
      );

      expect(result.comparedObjects, 0);
      expect(result.currentTotal, 0);
      expect(result.previousTotal, 0);
      expect(result.difference, 0);
    });

    test('uses quantity one when no quantity is supplied', () {
      final result = calculateCollectionValueComparison(
        currentValues: {'1': 30},
        previousValues: {'1': 24},
        quantities: const {},
      );

      expect(result.comparedObjects, 1);
      expect(result.currentTotal, 30);
      expect(result.previousTotal, 24);
    });
  });
}
