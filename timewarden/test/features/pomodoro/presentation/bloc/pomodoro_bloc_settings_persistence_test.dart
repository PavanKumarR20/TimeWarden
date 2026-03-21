import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timewarden/features/pomodoro/domain/entities/pomodoro_session.dart';
import 'package:timewarden/features/pomodoro/domain/entities/pomodoro_settings.dart';
import 'package:timewarden/features/pomodoro/domain/repositories/pomodoro_repository.dart';
import 'package:timewarden/features/pomodoro/domain/usecases/get_pomodoro_settings.dart';
import 'package:timewarden/features/pomodoro/domain/usecases/save_pomodoro_settings.dart';
import 'package:timewarden/features/pomodoro/presentation/bloc/pomodoro_bloc.dart';
import 'package:timewarden/features/pomodoro/presentation/bloc/pomodoro_event.dart';
import 'package:timewarden/features/pomodoro/presentation/bloc/pomodoro_state.dart';

class MockPomodoroRepository extends Mock implements PomodoroRepository {}

class MockGetPomodoroSettings extends Mock implements GetPomodoroSettings {}

class MockSavePomodoroSettings extends Mock implements SavePomodoroSettings {}

const MethodChannel _audioPlayersGlobalChannel =
    MethodChannel('xyz.luan/audioplayers.global');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPomodoroRepository mockPomodoroRepository;
  late MockGetPomodoroSettings mockGetPomodoroSettings;
  late MockSavePomodoroSettings mockSavePomodoroSettings;
  late PomodoroBloc bloc;

  setUpAll(() {
    registerFallbackValue(const PomodoroSettings());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      _audioPlayersGlobalChannel,
      (methodCall) async => null,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_audioPlayersGlobalChannel, null);
  });

  setUp(() {
    mockPomodoroRepository = MockPomodoroRepository();
    mockGetPomodoroSettings = MockGetPomodoroSettings();
    mockSavePomodoroSettings = MockSavePomodoroSettings();

    when(() => mockPomodoroRepository.getSessions())
        .thenAnswer((_) async => <PomodoroSession>[]);
    when(() => mockGetPomodoroSettings())
        .thenAnswer((_) async => const PomodoroSettings());
    when(() => mockSavePomodoroSettings(any())).thenAnswer((_) async {});

    bloc = PomodoroBloc(
      mockPomodoroRepository,
      mockGetPomodoroSettings,
      mockSavePomodoroSettings,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('PomodoroBloc settings persistence', () {
    blocTest<PomodoroBloc, PomodoroState>(
      'loads persisted settings when PomodoroLoadRequested is dispatched',
      build: () {
        const loadedSettings = PomodoroSettings(
          workDurationMinutes: 50,
          shortBreakMinutes: 7,
          longBreakMinutes: 18,
          sessionsUntilLongBreak: 4,
        );
        when(() => mockGetPomodoroSettings())
            .thenAnswer((_) async => loadedSettings);
        when(() => mockPomodoroRepository.getSessions())
            .thenAnswer((_) async => <PomodoroSession>[]);
        return bloc;
      },
      act: (bloc) => bloc.add(const PomodoroLoadRequested()),
      expect: () => [
        const PomodoroLoading(),
        const PomodoroReady(
          settings: PomodoroSettings(
            workDurationMinutes: 50,
            shortBreakMinutes: 7,
            longBreakMinutes: 18,
            sessionsUntilLongBreak: 4,
          ),
          completedWorkSessions: 0,
          isLongBreakNext: false,
        ),
      ],
      verify: (_) {
        verify(() => mockGetPomodoroSettings()).called(1);
        verify(() => mockPomodoroRepository.getSessions()).called(1);
      },
    );

    blocTest<PomodoroBloc, PomodoroState>(
      'persists and emits updated settings when PomodoroSettingsUpdated is dispatched in ready state',
      build: () => bloc,
      seed: () => const PomodoroReady(settings: PomodoroSettings()),
      act: (bloc) => bloc.add(
        const PomodoroSettingsUpdated(
          PomodoroSettings(
            workDurationMinutes: 35,
            shortBreakMinutes: 6,
            longBreakMinutes: 17,
            sessionsUntilLongBreak: 5,
          ),
        ),
      ),
      expect: () => [
        const PomodoroReady(
          settings: PomodoroSettings(
            workDurationMinutes: 35,
            shortBreakMinutes: 6,
            longBreakMinutes: 17,
            sessionsUntilLongBreak: 5,
          ),
          completedWorkSessions: 0,
          isLongBreakNext: false,
        ),
      ],
      verify: (_) {
        verify(
          () => mockSavePomodoroSettings(
            const PomodoroSettings(
              workDurationMinutes: 35,
              shortBreakMinutes: 6,
              longBreakMinutes: 17,
              sessionsUntilLongBreak: 5,
            ),
          ),
        ).called(1);
      },
    );
  });
}
