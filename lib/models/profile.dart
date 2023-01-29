import 'package:twitter_clone/constants.dart';

class Profile {
  final String id;
  final String name;
  final String? imageUrl;
  final String? description;

  Profile({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  Profile.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        imageUrl = json['image_path'] == null
            ? null
            : supabase.storage
                .from('profiles')
                .getPublicUrl(json['image_path']),
        description = json['description'];

  Profile copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? description,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Profile && other.hashCode == hashCode;
  }

  @override
  int get hashCode => id.hashCode;
}
