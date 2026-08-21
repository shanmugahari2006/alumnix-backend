import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/services/stories_service.dart';
import '../models/story.dart';
import 'auth_provider.dart';

final storiesServiceProvider = Provider<StoriesService>((ref) {
  final client = ref.watch(dioClientProvider);
  return StoriesService(client);
});

@immutable
class StoriesFeedState {
  final List<Story> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;

  const StoriesFeedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
  });

  StoriesFeedState copyWith({
    List<Story>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
  }) {
    return StoriesFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

final storiesFeedNotifierProvider =
    StateNotifierProvider<StoriesFeedNotifier, StoriesFeedState>((ref) {
  final service = ref.watch(storiesServiceProvider);
  return StoriesFeedNotifier(service);
});

class StoriesFeedNotifier extends StateNotifier<StoriesFeedState> {
  final StoriesService _service;

  StoriesFeedNotifier(this._service)
      : super(const StoriesFeedState(isLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial({bool refresh = false}) async {
    state = state.copyWith(isLoading: true);

    try {
      final stories = await _service.getStories();
      if (stories.isNotEmpty) {
        state = state.copyWith(
          items: stories,
          isLoading: false,
          hasMore: false,
          currentPage: 1,
        );
        return;
      }
    } catch (_) {}

    // Editorial Fallback Feed
    final mockStories = _getEditorialMockStories();
    state = state.copyWith(
      items: mockStories,
      isLoading: false,
      hasMore: false,
      currentPage: 1,
    );
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    // For pagination expansion
  }

  /// Optimistic Like Toggle with Rollback on Network Failure
  Future<bool> optimisticToggleLike(String storyId) async {
    final previousList = state.items;
    final targetIndex = previousList.indexWhere((s) => s.id == storyId);
    if (targetIndex == -1) return false;

    final targetStory = previousList[targetIndex];
    final newLiked = !targetStory.isLiked;
    final newCount =
        newLiked ? targetStory.likesCount + 1 : targetStory.likesCount - 1;

    final updatedStory = targetStory.copyWith(
      isLiked: newLiked,
      likesCount: newCount < 0 ? 0 : newCount,
    );

    // 1. Apply Optimistic Update Immediately
    final updatedList = List<Story>.from(previousList);
    updatedList[targetIndex] = updatedStory;
    state = state.copyWith(items: updatedList);

    // 2. Fire Network Request in Background
    try {
      await _service.toggleLike(storyId);
      return true;
    } catch (e) {
      // 3. Rollback on Failure
      state = state.copyWith(items: previousList);
      return false;
    }
  }

  List<Story> _getEditorialMockStories() {
    return [
      Story(
        id: 'story-1',
        title: 'Architecting Foundation Models at Scale: Lessons from the AI Frontier',
        content:
            'When we graduated from the Computer Science laboratory in 2018, the landscape of deep learning was on the precipice of a seismic shift.\n\nOver the past six years at Anthropic, our engineering team has navigated the challenges of training clusters spanning tens of thousands of GPUs, designing scalable telemetry, and unraveling the inner mechanics of neural attention.\n\nTo current undergraduates and researchers: the foundational principles taught in operating systems, distributed protocols, and linear algebra remain the bedrock of modern artificial intelligence. Never underestimate the power of deep understanding over superficial tooling. The future belongs to those who build from first principles.',
        authorId: 'alumni-1',
        authorName: 'Eleanor Vance',
        authorGradYear: 2018,
        authorDesignation: 'Senior Research Scientist, Anthropic AI',
        imageUrl:
            'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=80',
        likesCount: 142,
        isLiked: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Story(
        id: 'story-2',
        title: 'From College Lab Bench to Breakthrough CRISPR Therapeutics',
        content:
            'Our journey started in the basement biotech laboratory with a single thermal cycler and a hypothesis about targeted genetic editing.\n\nFast forward eight years: our startup has translated early academic discoveries into Phase II clinical trials for rare pediatric genetic disorders. Building a biotechnology enterprise requires immense perseverance, regulatory rigor, and an unwavering commitment to patient outcomes.\n\nThe collegiate alumni network provided our seed mentorship and angel backing. Stay close to your peers; they are the future co-founders, advisors, and scientific leaders of tomorrow.',
        authorId: 'alumni-3',
        authorName: 'Dr. Clara Thorne',
        authorGradYear: 2016,
        authorDesignation: 'Director of Molecular Bio, Biogen',
        imageUrl:
            'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?auto=format&fit=crop&w=1200&q=80',
        likesCount: 98,
        isLiked: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Story(
        id: 'story-3',
        title: 'The Quantum Computing Revolution: Cryogenics, Silicon, and Global Impact',
        content:
            'Constructing quantum processors that operate millikelvin above absolute zero presents mechanical and electrical challenges that stretch the boundaries of physics.\n\nReflecting on my decade in hardware engineering, the interdisciplinary collaboration between electrical engineering, materials science, and computer architecture has been the single most rewarding aspect of my career.\n\nFor students aspiring to enter quantum technologies: cultivate curiosity across discipline boundaries. The next breakthrough will happen at the intersection of classical silicon and quantum coherence.',
        authorId: 'alumni-2',
        authorName: 'Dr. Julian Hayes',
        authorGradYear: 2014,
        authorDesignation: 'VP of Hardware, Quantum Dynamics',
        imageUrl:
            'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?auto=format&fit=crop&w=1200&q=80',
        likesCount: 76,
        isLiked: false,
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
      Story(
        id: 'story-4',
        title: 'Venture Capital & Quantitative Markets: Navigating Global Volatility',
        content:
            'In quantitative trading and high-frequency market making, seconds are lifetimes. The intersection of rigorous stochastic calculus, low-latency C++, and behavioral economics is where fortunes are built and risk is mastered.\n\nAlumni from our institution now manage multi-billion dollar portfolios across Wall Street, London, and Singapore. The dedication instilled during our collegiate convocation years remains our guiding north star.',
        authorId: 'alumni-4',
        authorName: 'Marcus Sterling',
        authorGradYear: 2011,
        authorDesignation: 'Managing Director, Goldman Sachs',
        imageUrl:
            'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?auto=format&fit=crop&w=1200&q=80',
        likesCount: 115,
        isLiked: false,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ];
  }
}

final storyDetailProvider =
    FutureProvider.family<Story?, String>((ref, id) async {
  final feed = ref.watch(storiesFeedNotifierProvider);
  try {
    return feed.items.firstWhere((s) => s.id == id);
  } catch (_) {
    final service = ref.watch(storiesServiceProvider);
    try {
      return await service.getStoryById(id);
    } catch (_) {
      return null;
    }
  }
});
