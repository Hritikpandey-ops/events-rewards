class NewsModel {
  final String id;
  final String title;
  final String content;
  final String? summary;
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final bool isPublished;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    this.category,
    this.imageUrl,
    required this.createdAt,
    this.publishedAt,
    this.isPublished = true,
  });

  // Factory constructor from JSON
  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      isPublished: json['is_published'] as bool? ?? true,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'category': category,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
      'is_published': isPublished,
    };
  }

  // Helper getters
  String get formattedDate {
    final date = publishedAt ?? createdAt;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  String get readingTime {
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 200).ceil(); // Average reading speed: 200 words/minute
    return '${minutes}min read';
  }

  String get preview {
    if (summary != null && summary!.isNotEmpty) {
      return summary!;
    }

    if (content.length <= 150) {
      return content;
    }

    return '${content.substring(0, 150)}...';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NewsModel(id: $id, title: $title, category: $category)';
  }
}