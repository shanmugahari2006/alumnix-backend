import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/services/events_service.dart';
import '../models/bulletin_event.dart';
import 'auth_provider.dart';

final eventsServiceProvider = Provider<EventsService>((ref) {
  final client = ref.watch(dioClientProvider);
  return EventsService(client);
});

/// Set of registered event IDs for current user session
final registeredEventsProvider =
    StateNotifierProvider<RegisteredEventsNotifier, Set<String>>((ref) {
  return RegisteredEventsNotifier();
});

class RegisteredEventsNotifier extends StateNotifier<Set<String>> {
  RegisteredEventsNotifier() : super({'event-1'}); // Demo default registered

  void markRegistered(String eventId) {
    state = {...state, eventId};
  }

  void unmark(String eventId) {
    state = state.where((id) => id != eventId).toSet();
  }

  bool isRegistered(String eventId) => state.contains(eventId);
}

final eventsListProvider =
    StateNotifierProvider<EventsListNotifier, AsyncValue<List<BulletinEvent>>>(
  (ref) {
    final service = ref.watch(eventsServiceProvider);
    return EventsListNotifier(service, ref);
  },
);

class EventsListNotifier extends StateNotifier<AsyncValue<List<BulletinEvent>>> {
  final EventsService _service;
  final Ref _ref;

  EventsListNotifier(this._service, this._ref)
      : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final list = await _service.getEvents();
      if (list.isNotEmpty) {
        // Sort soonest event_date first
        list.sort((a, b) => a.eventDate.compareTo(b.eventDate));
        state = AsyncValue.data(list);
        return;
      }
    } catch (_) {}

    // Curated Fallback Events sorted by soonest date first
    final now = DateTime.now();
    final mockEvents = [
      BulletinEvent(
        id: 'event-1',
        title: 'Global Alumni Convocation & Founders Summit 2026',
        description:
            'The signature annual gathering of institutional alumni, collegiate entrepreneurs, and faculty deans. Keynote addresses from distinguished tech founders, research symposiums, and an evening formal dinner in the Grand Quadrangle.',
        eventDate: now.add(const Duration(days: 3, hours: 4)),
        registrationDeadline: now.add(const Duration(days: 2, hours: 2)),
        location: 'Main Auditorium & Great Hall',
        creatorId: 'faculty-1',
        creatorName: 'Prof. Julian Hayes (Dean of Academics)',
        registeredCount: 342,
        isRegistered: true,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      BulletinEvent(
        id: 'event-2',
        title: 'Frontiers in Neuromorphic Silicon & AI Hardware Workshop',
        description:
            'A deep-dive technical symposium hosted by the Department of Electrical & Computer Engineering. Featuring research papers on memristor architectures, sub-threshold analog circuits, and photonic interconnects.',
        eventDate: now.add(const Duration(days: 7, hours: 9)),
        registrationDeadline: now.add(const Duration(days: 5, hours: 18)),
        location: 'Sir M.V. Seminar Hall, Block C',
        creatorId: 'faculty-2',
        creatorName: 'Dr. Clara Thorne',
        registeredCount: 88,
        isRegistered: false,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      BulletinEvent(
        id: 'event-3',
        title: 'Venture Capital Office Hours & Seed Pitch Session',
        description:
            'Direct 1-on-1 pitch clinics with institutional venture capital partners and angel alumni. Open to student and recent alumni startups seeking pre-seed and seed syndication.',
        eventDate: now.add(const Duration(days: 12, hours: 14)),
        registrationDeadline: now.add(const Duration(days: 10, hours: 23)),
        location: 'Incubation Center, Innovation Hub',
        creatorId: 'admin-1',
        creatorName: 'Alumni Innovation Council',
        registeredCount: 54,
        isRegistered: false,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      BulletinEvent(
        id: 'event-4',
        title: 'Biotech Lab Open House & CRISPR Showcase',
        description:
            'Interactive demonstration of gene sequencing instruments, automated liquid handlers, and cellular therapy bioreactors. Open to undergraduates and visiting scholars.',
        eventDate: now.subtract(const Duration(days: 2)),
        registrationDeadline: now.subtract(const Duration(days: 4)),
        location: 'Biotechnology Research Complex',
        creatorId: 'faculty-3',
        creatorName: 'Dept. of Bio-Engineering',
        registeredCount: 160,
        isRegistered: false,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    ];

    // Ensure sorted soonest first
    mockEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    state = AsyncValue.data(mockEvents);
  }

  /// Optimistic Event Registration
  Future<bool> registerOptimistic(String eventId) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return false;

    // 1. Optimistically update local state
    final updatedList = currentList.map((e) {
      if (e.id == eventId) {
        return e.copyWith(
          isRegistered: true,
          registeredCount: e.registeredCount + 1,
        );
      }
      return e;
    }).toList();

    state = AsyncValue.data(updatedList);
    _ref.read(registeredEventsProvider.notifier).markRegistered(eventId);

    // 2. Dispatch to backend
    try {
      await _service.registerForEvent(eventId);
      return true;
    } catch (e) {
      // 3. Rollback on failure
      state = AsyncValue.data(currentList);
      _ref.read(registeredEventsProvider.notifier).unmark(eventId);
      return false;
    }
  }

  /// Optimistic Event Deletion
  Future<bool> deleteEvent(String eventId) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return false;

    // 1. Optimistic removal
    final updatedList = currentList.where((e) => e.id != eventId).toList();
    state = AsyncValue.data(updatedList);

    // 2. Dispatch backend delete
    try {
      await _service.deleteEvent(eventId);
      return true;
    } catch (e) {
      // 3. Rollback on failure
      state = AsyncValue.data(currentList);
      return false;
    }
  }
}

final eventDetailProvider =
    FutureProvider.family<BulletinEvent?, String>((ref, id) async {
  final listAsync = ref.watch(eventsListProvider);
  final registeredSet = ref.watch(registeredEventsProvider);
  final list = listAsync.valueOrNull;

  if (list != null) {
    try {
      final item = list.firstWhere((e) => e.id == id);
      return item.copyWith(isRegistered: registeredSet.contains(id));
    } catch (_) {}
  }

  final service = ref.watch(eventsServiceProvider);
  try {
    final item = await service.getEventById(id);
    return item.copyWith(isRegistered: registeredSet.contains(id));
  } catch (_) {
    return null;
  }
});
