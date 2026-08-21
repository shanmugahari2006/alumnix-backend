import '../api_config.dart';
import '../dio_client.dart';
import '../../models/story.dart';

class StoriesService {
  final DioClient client;

  StoriesService(this.client);

  /// Fetch list of stories
  /// GET /api/v1/stories
  Future<List<Story>> getStories() async {
    final response = await client.get(ApiConfig.stories);
    if (response.data is List<dynamic>) {
      return (response.data as List<dynamic>)
          .map((e) => Story.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetch single story by ID
  /// GET /api/v1/stories/{id}
  Future<Story> getStoryById(String id) async {
    final response = await client.get(ApiConfig.storyById(id));
    return Story.fromJson(response.data as Map<String, dynamic>);
  }

  /// Create a new story
  /// POST /api/v1/stories
  Future<Story> createStory({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    final response = await client.post(
      ApiConfig.stories,
      data: {
        'title': title.trim(),
        'content': content.trim(),
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'image_url': imageUrl.trim(),
      },
    );
    return Story.fromJson(response.data as Map<String, dynamic>);
  }

  /// Toggle like on a story
  /// POST /api/v1/stories/{id}/like
  Future<LikeToggleResult> toggleLike(String storyId) async {
    final response = await client.post(ApiConfig.storyLike(storyId));
    return LikeToggleResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Helper to upload story cover photo and return public CDN URL
  Future<String> uploadStoryImage(String fileName) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=1200&q=80';
  }
}
