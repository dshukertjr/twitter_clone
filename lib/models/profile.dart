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

  Profile.fromJson(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        imageUrl = map['image_url'],
        description = map['description'];
}