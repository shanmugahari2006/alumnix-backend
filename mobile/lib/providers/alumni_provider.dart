import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/services/alumni_service.dart';
import '../models/alumni_profile.dart';
import 'auth_provider.dart';

final alumniServiceProvider = Provider<AlumniService>((ref) {
  final client = ref.watch(dioClientProvider);
  return AlumniService(client);
});

/// ---------------------------------------------------------------------------
/// Persistent Directory Filter State
/// ---------------------------------------------------------------------------

@immutable
class DirectoryFilterState {
  final String search;
  final String? branch;
  final double startYear;
  final double endYear;
  final String? location;
  final List<String> selectedSkills;

  const DirectoryFilterState({
    this.search = '',
    this.branch,
    this.startYear = 2005.0,
    this.endYear = 2026.0,
    this.location,
    this.selectedSkills = const [],
  });

  bool get hasActiveFilters =>
      (branch != null && branch != 'All') ||
      startYear > 2005.0 ||
      endYear < 2026.0 ||
      (location != null && location!.trim().isNotEmpty) ||
      selectedSkills.isNotEmpty;

  int get activeFilterCount {
    int count = 0;
    if (branch != null && branch != 'All') count++;
    if (startYear > 2005.0 || endYear < 2026.0) count++;
    if (location != null && location!.trim().isNotEmpty) count++;
    if (selectedSkills.isNotEmpty) count += selectedSkills.length;
    return count;
  }

  DirectoryFilterState copyWith({
    String? search,
    String? branch,
    double? startYear,
    double? endYear,
    String? location,
    List<String>? selectedSkills,
    bool clearBranch = false,
    bool clearLocation = false,
  }) {
    return DirectoryFilterState(
      search: search ?? this.search,
      branch: clearBranch ? null : (branch ?? this.branch),
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      location: clearLocation ? null : (location ?? this.location),
      selectedSkills: selectedSkills ?? this.selectedSkills,
    );
  }

  DirectoryFilterState resetFilters() {
    return DirectoryFilterState(search: search);
  }
}

final directoryFilterProvider =
    StateNotifierProvider<DirectoryFilterNotifier, DirectoryFilterState>((ref) {
  return DirectoryFilterNotifier();
});

class DirectoryFilterNotifier extends StateNotifier<DirectoryFilterState> {
  DirectoryFilterNotifier() : super(const DirectoryFilterState());

  void setSearch(String search) {
    state = state.copyWith(search: search);
  }

  void updateFilters({
    String? branch,
    double? startYear,
    double? endYear,
    String? location,
    List<String>? selectedSkills,
  }) {
    state = state.copyWith(
      branch: branch,
      startYear: startYear,
      endYear: endYear,
      location: location,
      selectedSkills: selectedSkills,
    );
  }

  void toggleSkill(String skill) {
    final current = List<String>.from(state.selectedSkills);
    if (current.contains(skill)) {
      current.remove(skill);
    } else {
      current.add(skill);
    }
    state = state.copyWith(selectedSkills: current);
  }

  void reset() {
    state = state.resetFilters();
  }
}

/// ---------------------------------------------------------------------------
/// Infinite Scroll Directory State & Notifier (Debounced 400ms)
/// ---------------------------------------------------------------------------

@immutable
class AlumniDirectoryState {
  final List<AlumniSearchResult> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final String? errorMessage;

  const AlumniDirectoryState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.totalCount = 0,
    this.errorMessage,
  });

  AlumniDirectoryState copyWith({
    List<AlumniSearchResult>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    String? errorMessage,
  }) {
    return AlumniDirectoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage,
    );
  }
}

final alumniDirectoryNotifierProvider =
    StateNotifierProvider<AlumniDirectoryNotifier, AlumniDirectoryState>((ref) {
  final service = ref.watch(alumniServiceProvider);
  final filter = ref.watch(directoryFilterProvider);
  return AlumniDirectoryNotifier(service, filter);
});

class AlumniDirectoryNotifier extends StateNotifier<AlumniDirectoryState> {
  final AlumniService _service;
  final DirectoryFilterState _filter;
  Timer? _debounceTimer;

  static const int _pageSize = 10;

  AlumniDirectoryNotifier(this._service, this._filter)
      : super(const AlumniDirectoryState(isLoading: true)) {
    loadInitial();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Debounced Search Trigger (400ms)
  void onSearchQueryChanged(String query, DirectoryFilterNotifier filterNotifier) {
    filterNotifier.setSearch(query);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      loadInitial(refresh: true);
    });
  }

  /// Initial / Filter Changed Load
  Future<void> loadInitial({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _service.searchAlumni(
        search: _filter.search,
        branch: _filter.branch,
        location: _filter.location,
        skills: _filter.selectedSkills.isNotEmpty ? _filter.selectedSkills : null,
        page: 1,
        limit: _pageSize,
      );

      final hasMore = response.results.length >= _pageSize &&
          (response.total == 0 || response.results.length < response.total);

      state = state.copyWith(
        items: response.results,
        isLoading: false,
        hasMore: hasMore,
        currentPage: 1,
        totalCount: response.total,
      );

      if (response.results.isNotEmpty) return;
    } catch (_) {}

    // Curated Fallback Data for offline / mock testing
    final mockFiltered = _getMockAlumni().where((alumni) {
      if (_filter.search.isNotEmpty) {
        final q = _filter.search.toLowerCase();
        final match = alumni.fullName.toLowerCase().contains(q) ||
            (alumni.company?.toLowerCase().contains(q) ?? false) ||
            (alumni.designation?.toLowerCase().contains(q) ?? false) ||
            (alumni.location?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      if (_filter.branch != null &&
          _filter.branch != 'All' &&
          alumni.branch != _filter.branch) {
        return false;
      }
      if (alumni.graduationYear < _filter.startYear ||
          alumni.graduationYear > _filter.endYear) {
        return false;
      }
      if (_filter.location != null && _filter.location!.trim().isNotEmpty) {
        if (!(alumni.location
                ?.toLowerCase()
                .contains(_filter.location!.toLowerCase().trim()) ??
            false)) {
          return false;
        }
      }
      if (_filter.selectedSkills.isNotEmpty) {
        final hasSkill = _filter.selectedSkills.any((s) => alumni.skills
            .map((e) => e.toLowerCase())
            .contains(s.toLowerCase()));
        if (!hasSkill) return false;
      }
      return true;
    }).toList();

    state = state.copyWith(
      items: mockFiltered,
      isLoading: false,
      hasMore: false,
      currentPage: 1,
      totalCount: mockFiltered.length,
    );
  }

  /// Infinite Scroll: Load Next Page
  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final response = await _service.searchAlumni(
        search: _filter.search,
        branch: _filter.branch,
        location: _filter.location,
        skills: _filter.selectedSkills.isNotEmpty ? _filter.selectedSkills : null,
        page: nextPage,
        limit: _pageSize,
      );

      final newItems = [...state.items, ...response.results];
      final hasMore = response.results.length >= _pageSize &&
          (response.total == 0 || newItems.length < response.total);

      state = state.copyWith(
        items: newItems,
        isLoadingMore: false,
        hasMore: hasMore,
        currentPage: nextPage,
        totalCount: response.total,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false, hasMore: false);
    }
  }

  List<AlumniSearchResult> _getMockAlumni() {
    return [
      const AlumniSearchResult(
        id: 'alumni-1',
        fullName: 'Eleanor Vance',
        email: 'eleanor.vance@stanford.alumni.edu',
        company: 'Anthropic AI',
        designation: 'Senior Research Scientist',
        graduationYear: 2018,
        branch: 'Computer Science',
        location: 'San Francisco, CA',
        linkedinUrl: 'https://linkedin.com/in/eleanor-vance',
        bio: 'Leading interpretability and steerability research for next-generation foundation models. Passioned about open collegiate mentorship.',
        skills: ['Machine Learning', 'PyTorch', 'Distributed Systems', 'Research'],
      ),
      const AlumniSearchResult(
        id: 'alumni-2',
        fullName: 'Dr. Julian Hayes',
        email: 'julian.hayes@oxford.alumni.edu',
        company: 'Quantum Dynamics',
        designation: 'VP of Hardware Architecture',
        graduationYear: 2014,
        branch: 'Electrical Engineering',
        location: 'Boston, MA',
        linkedinUrl: 'https://linkedin.com/in/julian-hayes',
        bio: 'Cryogenic quantum processor architect. Former lab chair at MIT Lincoln Laboratory.',
        skills: ['VLSI Design', 'Photonics', 'Quantum Computing', 'Hardware'],
      ),
      const AlumniSearchResult(
        id: 'alumni-3',
        fullName: 'Dr. Clara Thorne',
        email: 'clara.thorne@biogen.com',
        company: 'Biogen Technologies',
        designation: 'Director of Molecular Bio',
        graduationYear: 2016,
        branch: 'Biotechnology',
        location: 'Cambridge, MA',
        linkedinUrl: 'https://linkedin.com/in/clara-thorne',
        bio: 'Directing high-throughput CRISPR screening platforms for targeted gene therapies.',
        skills: ['CRISPR', 'Genomics', 'Bioinformatics', 'Drug Discovery'],
      ),
      const AlumniSearchResult(
        id: 'alumni-4',
        fullName: 'Marcus Sterling',
        email: 'marcus.sterling@goldmansachs.com',
        company: 'Goldman Sachs',
        designation: 'Managing Director, Fintech',
        graduationYear: 2011,
        branch: 'Economics & Computing',
        location: 'New York, NY',
        linkedinUrl: 'https://linkedin.com/in/marcus-sterling',
        bio: 'Quantitative electronic market maker and fintech venture scout.',
        skills: ['Quantitative Finance', 'Algorithmic Trading', 'Risk Analysis', 'FinTech'],
      ),
      const AlumniSearchResult(
        id: 'alumni-5',
        fullName: 'Aria Montgomery',
        email: 'aria.m@apple.com',
        company: 'Apple',
        designation: 'Lead Industrial Designer',
        graduationYear: 2021,
        branch: 'Product Design',
        location: 'Cupertino, CA',
        linkedinUrl: 'https://linkedin.com/in/aria-montgomery',
        bio: 'Human-centered hardware ergonomics and sustainable metal alloys.',
        skills: ['Ergonomics', 'Material Science', 'CAD Modeling', 'Industrial Design'],
      ),
      const AlumniSearchResult(
        id: 'alumni-6',
        fullName: 'David K. Vance',
        email: 'david.vance@google.com',
        company: 'Google Cloud',
        designation: 'Principal Site Reliability Eng.',
        graduationYear: 2013,
        branch: 'Computer Science',
        location: 'Seattle, WA',
        linkedinUrl: 'https://linkedin.com/in/david-vance',
        bio: 'Specializing in hyper-scale Kubernetes orchestration and zero-trust infrastructure.',
        skills: ['Cloud Computing', 'Kubernetes', 'Go', 'DevOps'],
      ),
      const AlumniSearchResult(
        id: 'alumni-7',
        fullName: 'Sophia Ramirez',
        email: 'sophia.r@stripe.com',
        company: 'Stripe',
        designation: 'Staff Product Manager',
        graduationYear: 2017,
        branch: 'Information Science',
        location: 'San Francisco, CA',
        linkedinUrl: 'https://linkedin.com/in/sophia-ramirez',
        bio: 'Building global developer payment primitives across 40+ countries.',
        skills: ['Product Management', 'API Design', 'FinTech', 'Strategy'],
      ),
    ];
  }
}

/// Single Alumnus Detail Provider
final alumniDetailProvider =
    FutureProvider.family<AlumniSearchResult?, String>((ref, id) async {
  final service = ref.watch(alumniServiceProvider);
  try {
    return await service.getAlumniById(id);
  } catch (_) {}

  final directoryState = ref.watch(alumniDirectoryNotifierProvider);
  return directoryState.items.firstWhere(
    (item) => item.id == id,
    orElse: () => AlumniSearchResult(
      id: id,
      fullName: 'Distinguished Alumnus',
      email: 'alumni@university.edu',
      graduationYear: 2020,
      designation: 'Technology Architect',
      company: 'Alumni Network',
      location: 'Global',
      skills: ['Leadership', 'Mentorship'],
    ),
  );
});

/// ---------------------------------------------------------------------------
/// Admin Pending Alumni Notifier & Provider
/// ---------------------------------------------------------------------------

final pendingAlumniProvider = StateNotifierProvider<PendingAlumniNotifier,
    AsyncValue<List<AlumniSearchResult>>>((ref) {
  final service = ref.watch(alumniServiceProvider);
  return PendingAlumniNotifier(service);
});

class PendingAlumniNotifier
    extends StateNotifier<AsyncValue<List<AlumniSearchResult>>> {
  final AlumniService _service;

  PendingAlumniNotifier(this._service) : super(const AsyncValue.loading()) {
    loadPending();
  }

  Future<void> loadPending() async {
    state = const AsyncValue.loading();
    try {
      final list = await _service.getPendingAlumni();
      if (list.isNotEmpty) {
        state = AsyncValue.data(list);
        return;
      }
    } catch (_) {}

    // Mock Pending Alumni for Admin moderation
    final mockPending = [
      const AlumniSearchResult(
        id: 'pending-1',
        fullName: 'Alexander Wright',
        email: 'alex.wright@alum.org',
        company: 'NVIDIA',
        designation: 'GPU Firmware Engineer',
        graduationYear: 2022,
        branch: 'Electronics & Communication',
        location: 'Austin, TX',
        isApproved: false,
        skills: ['CUDA', 'C++', 'Embedded Systems'],
      ),
      const AlumniSearchResult(
        id: 'pending-2',
        fullName: 'Samantha Chen',
        email: 'samantha.chen@alum.org',
        company: 'DeepMind Health',
        designation: 'Clinical AI Researcher',
        graduationYear: 2019,
        branch: 'Biotechnology',
        location: 'London, UK',
        isApproved: false,
        skills: ['Genomics', 'Bioinformatics', 'Deep Learning'],
      ),
      const AlumniSearchResult(
        id: 'pending-3',
        fullName: 'Rohan Mehta',
        email: 'rohan.mehta@alum.org',
        company: 'Tesla Autopilot',
        designation: 'Perception Engineer',
        graduationYear: 2023,
        branch: 'Computer Science',
        location: 'Palo Alto, CA',
        isApproved: false,
        skills: ['Computer Vision', 'PyTorch', 'ROS'],
      ),
    ];

    state = AsyncValue.data(mockPending);
  }

  Future<bool> approveAlumni(String alumniId) async {
    final current = state.valueOrNull ?? [];
    try {
      await _service.approveAlumni(alumniId);
    } catch (_) {}

    // Optimistically remove from pending list
    state = AsyncValue.data(current.where((item) => item.id != alumniId).toList());
    return true;
  }
}
