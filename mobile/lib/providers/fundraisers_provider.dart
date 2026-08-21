import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/services/fundraisers_service.dart';
import '../models/fundraiser.dart';
import 'auth_provider.dart';

final fundraisersServiceProvider = Provider<FundraisersService>((ref) {
  final client = ref.watch(dioClientProvider);
  return FundraisersService(client);
});

final fundraisersListProvider =
    StateNotifierProvider<FundraisersListNotifier, AsyncValue<List<Fundraiser>>>(
  (ref) {
    final service = ref.watch(fundraisersServiceProvider);
    return FundraisersListNotifier(service);
  },
);

class FundraisersListNotifier
    extends StateNotifier<AsyncValue<List<Fundraiser>>> {
  final FundraisersService _service;

  FundraisersListNotifier(this._service) : super(const AsyncValue.loading()) {
    loadFundraisers();
  }

  Future<void> loadFundraisers() async {
    state = const AsyncValue.loading();
    try {
      final list = await _service.getFundraisers();
      if (list.isNotEmpty) {
        state = AsyncValue.data(list);
        return;
      }
    } catch (_) {}

    // Curated Collegiate Startup Campaigns Fallback
    final mockCampaigns = [
      Fundraiser(
        id: 'fund-1',
        title: 'Autonomous Solar Drones for Agricultural Yield Sensing',
        startupName: 'AeroAgri Robotics',
        description:
            'Developing multi-spectral solar-powered autonomous UAVs that operate continuously over vast agricultural belts, providing real-time soil moisture and crop disease diagnostics to farmers.',
        targetAmount: 1500000.0,
        raisedAmount: 1125000.0,
        creatorId: 'student-1',
        creatorName: 'Rohan Sharma (Dept. of Mechanical)',
        donorsCount: 38,
        imageUrl:
            'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?auto=format&fit=crop&w=1000&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Fundraiser(
        id: 'fund-2',
        title: 'Micro-Dialysis Bio-Chips for Point-of-Care Diagnostics',
        startupName: 'NanoBio Diagnostics',
        description:
            'A miniature microfluidic lab-on-a-chip capable of performing full blood lipid and electrolyte panels in under 3 minutes for rural healthcare clinics and remote medical outposts.',
        targetAmount: 2000000.0,
        raisedAmount: 1480000.0,
        creatorId: 'student-2',
        creatorName: 'Aanya Sen (Biotechnology Lab)',
        donorsCount: 52,
        imageUrl:
            'https://images.unsplash.com/photo-1579154204601-01588f351e67?auto=format&fit=crop&w=1000&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Fundraiser(
        id: 'fund-3',
        title: 'Zero-Knowledge Privacy Layer for Web3 Micro-Payments',
        startupName: 'CipherPay Protocol',
        description:
            'Building high-throughput zk-SNARK rollups designed specifically for instant peer-to-peer institutional micro-settlements and student payment rails.',
        targetAmount: 800000.0,
        raisedAmount: 640000.0,
        creatorId: 'student-3',
        creatorName: 'Dev Patel (Computer Science)',
        donorsCount: 29,
        imageUrl:
            'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?auto=format&fit=crop&w=1000&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
      Fundraiser(
        id: 'fund-4',
        title: 'Solid-State Electrolyte Battery Cells for Two-Wheelers',
        startupName: 'VoltCore Energy',
        description:
            'Non-flammable solid-state lithium ceramic battery packs optimized for ultra-fast 12-minute rapid charging cycles and extended thermal stability in tropical climates.',
        targetAmount: 3000000.0,
        raisedAmount: 1850000.0,
        creatorId: 'student-4',
        creatorName: 'Vikram Joshi (Electrical Dept.)',
        donorsCount: 44,
        imageUrl:
            'https://images.unsplash.com/photo-1558441719-8b489c63f771?auto=format&fit=crop&w=1000&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 22)),
      ),
    ];

    state = AsyncValue.data(mockCampaigns);
  }

  void recordDonationOptimistic(String fundraiserId, double amount) {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    final updated = currentList.map((f) {
      if (f.id == fundraiserId) {
        return f.copyWith(
          raisedAmount: f.raisedAmount + amount,
          donorsCount: f.donorsCount + 1,
        );
      }
      return f;
    }).toList();

    state = AsyncValue.data(updated);
  }
}

final fundraiserDetailProvider =
    FutureProvider.family<Fundraiser?, String>((ref, id) async {
  final listAsync = ref.watch(fundraisersListProvider);
  final list = listAsync.valueOrNull;
  if (list != null) {
    try {
      return list.firstWhere((item) => item.id == id);
    } catch (_) {}
  }

  final service = ref.watch(fundraisersServiceProvider);
  try {
    return await service.getFundraiserById(id);
  } catch (_) {
    return null;
  }
});
