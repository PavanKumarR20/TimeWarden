import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timewarden/features/habits/presentation/bloc/habits_bloc.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  late MockHabitRepository mockRepository;
  late HabitsBloc bloc;

  setUpAll(() {
    registerFallbackValue(TestHabits.testHabit1);
  });

  setUp(() {
    mockRepository = MockHabitRepository();
    bloc = HabitsBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('HabitsBloc', () {
    test('initial state is HabitsInitial', () {
      expect(bloc.state, equals(HabitsInitial()));
    });

    group('HabitsLoadRequested', () {
      blocTest<HabitsBloc, HabitsState>(
        'emits [HabitsLoading, HabitsLoaded] when habits are loaded successfully',
        build: () {
          when(() => mockRepository.getHabits())
              .thenAnswer((_) async => TestHabits.all);
          return bloc;
        },
        act: (bloc) => bloc.add(HabitsLoadRequested()),
        expect: () => [
          HabitsLoading(),
          HabitsLoaded(TestHabits.all),
        ],
        verify: (_) {
          verify(() => mockRepository.getHabits()).called(1);
        },
      );

      blocTest<HabitsBloc, HabitsState>(
        'emits [HabitsLoading, HabitsLoaded] with empty list when no habits exist',
        build: () {
          when(() => mockRepository.getHabits()).thenAnswer((_) async => []);
          return bloc;
        },
        act: (bloc) => bloc.add(HabitsLoadRequested()),
        expect: () => [
          HabitsLoading(),
          const HabitsLoaded([]),
        ],
      );

      blocTest<HabitsBloc, HabitsState>(
        'emits [HabitsLoading, HabitsError] when loading fails',
        build: () {
          when(() => mockRepository.getHabits())
              .thenThrow(Exception('Failed to load habits'));
          return bloc;
        },
        act: (bloc) => bloc.add(HabitsLoadRequested()),
        expect: () => [
          HabitsLoading(),
          isA<HabitsError>(),
        ],
      );
    });

    group('HabitAdded', () {
      final newHabit = TestHabits.testHabit1;

      blocTest<HabitsBloc, HabitsState>(
        'adds habit and reloads habit list',
        build: () {
          when(() => mockRepository.addHabit(any()))
              .thenAnswer((_) async => {});
          when(() => mockRepository.getHabits())
              .thenAnswer((_) async => [newHabit]);
          return bloc;
        },
        act: (bloc) => bloc.add(HabitAdded(newHabit)),
        expect: () => [
          HabitsLoading(),
          HabitsLoaded([newHabit]),
        ],
        verify: (_) {
          verify(() => mockRepository.addHabit(newHabit)).called(1);
          verify(() => mockRepository.getHabits()).called(1);
        },
      );

      blocTest<HabitsBloc, HabitsState>(
        'emits HabitsError when adding habit fails',
        build: () {
          when(() => mockRepository.addHabit(any()))
              .thenThrow(Exception('Failed to add habit'));
          return bloc;
        },
        act: (bloc) => bloc.add(HabitAdded(newHabit)),
        expect: () => [
          isA<HabitsError>(),
        ],
      );
    });

    group('HabitUpdated', () {
      final updatedHabit = TestHabits.testHabit1.copyWith(name: 'Updated Name');

      blocTest<HabitsBloc, HabitsState>(
        'updates habit and reloads habit list',
        build: () {
          when(() => mockRepository.updateHabit(any()))
              .thenAnswer((_) async => {});
          when(() => mockRepository.getHabits())
              .thenAnswer((_) async => [updatedHabit]);
          return bloc;
        },
        act: (bloc) => bloc.add(HabitUpdated(updatedHabit)),
        expect: () => [
          HabitsLoading(),
          HabitsLoaded([updatedHabit]),
        ],
        verify: (_) {
          verify(() => mockRepository.updateHabit(updatedHabit)).called(1);
          verify(() => mockRepository.getHabits()).called(1);
        },
      );
    });

    group('HabitDeleted', () {
      const habitId = 'test-1';

      blocTest<HabitsBloc, HabitsState>(
        'deletes habit and reloads habit list',
        build: () {
          when(() => mockRepository.deleteHabit(any()))
              .thenAnswer((_) async => {});
          when(() => mockRepository.getHabits()).thenAnswer((_) async => []);
          return bloc;
        },
        act: (bloc) => bloc.add(const HabitDeleted(habitId)),
        expect: () => [
          HabitsLoading(),
          const HabitsLoaded([]),
        ],
        verify: (_) {
          verify(() => mockRepository.deleteHabit(habitId)).called(1);
          verify(() => mockRepository.getHabits()).called(1);
        },
      );
    });

    group('HabitCompletionToggled', () {
      final habit = TestHabits.testHabit1;
      final today = DateTime.now();

      blocTest<HabitsBloc, HabitsState>(
        'marks habit as complete when not already completed',
        build: () {
          when(() => mockRepository.markHabitComplete(any(), any()))
              .thenAnswer((_) async => {});
          return bloc;
        },
        seed: () => HabitsLoaded([habit]),
        act: (bloc) =>
            bloc.add(HabitCompletionToggled(habitId: habit.id, date: today)),
        expect: () => [
          isA<HabitsLoaded>().having(
            (state) => state.habits.first.completedDates.length,
            'completed dates length',
            1,
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.markHabitComplete(habit.id, today))
              .called(1);
        },
      );

      blocTest<HabitsBloc, HabitsState>(
        'marks habit as incomplete when already completed',
        build: () {
          when(() => mockRepository.markHabitIncomplete(any(), any()))
              .thenAnswer((_) async => {});
          return bloc;
        },
        seed: () => HabitsLoaded([
          habit.copyWith(
            completedDates: [DateTime(today.year, today.month, today.day)],
          )
        ]),
        act: (bloc) =>
            bloc.add(HabitCompletionToggled(habitId: habit.id, date: today)),
        expect: () => [
          isA<HabitsLoaded>().having(
            (state) => state.habits.first.completedDates.length,
            'completed dates length',
            0,
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.markHabitIncomplete(habit.id, today))
              .called(1);
        },
      );
    });
  });
}
