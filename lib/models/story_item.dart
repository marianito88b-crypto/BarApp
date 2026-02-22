import 'package:cloud_firestore/cloud_firestore.dart';

class StoryItem {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String mediaUrl;
  final String mediaType;
  final String? thumbnailUrl;
  final bool isFeatured;
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final Map<String, int> reactions;
  final Map<String, String> reactionsUsers;
  final int commentsCount;
  final List<String> viewers;

  StoryItem({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.mediaUrl,
    required this.mediaType,
    required this.isFeatured,
    required this.createdAt,
    required this.expiresAt,
    this.thumbnailUrl,
    required this.reactions,
    required this.reactionsUsers,
    required this.commentsCount,
    required this.viewers,
  });

  factory StoryItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data()!;
    return StoryItem(
      id: d.id,
      authorId: (data['authorId'] ?? '') as String,
      authorName: (data['authorName'] ?? 'Usuario') as String,
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      mediaUrl: (data['mediaUrl'] ?? '') as String,
      mediaType: (data['mediaType'] ?? 'image') as String,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      isFeatured: (data['isFeatured'] ?? false) as bool,
      createdAt: (data['createdAt'] ?? Timestamp.now()) as Timestamp,
      expiresAt: (data['expiresAt'] ?? Timestamp.now()) as Timestamp,
      reactions: Map<String, int>.from(data['reactions'] ?? const {}),
      reactionsUsers: Map<String, String>.from(
        (data['reactionsUsers'] ?? const {}).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      ),
      commentsCount: (data['commentsCount'] ?? 0) as int,
      viewers: List<String>.from(data['viewers'] ?? []),
    );
  }

  // Se agregó isFeatured aquí para poder actualizarlo dinámicamente
  StoryItem copyWith({
    Map<String, int>? reactions,
    Map<String, String>? reactionsUsers,
    int? commentsCount,
    List<String>? viewers,
    bool? isFeatured, 
  }) {
    return StoryItem(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      thumbnailUrl: thumbnailUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt,
      expiresAt: expiresAt,
      reactions: reactions ?? this.reactions,
      reactionsUsers: reactionsUsers ?? this.reactionsUsers,
      commentsCount: commentsCount ?? this.commentsCount,
      viewers: viewers ?? this.viewers,
    );
  }
}