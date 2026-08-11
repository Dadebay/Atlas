import 'package:atlas/core/services/api_constants.dart';

class BrandModel {
  final int id;
  final String name;
  final String image;
  final int queuePosition;

  const BrandModel({
    required this.id,
    required this.name,
    required this.image,
    required this.queuePosition,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image']?.toString() ?? '';
    final image = rawImage.isEmpty
        ? ''
        : rawImage.startsWith('http')
            ? rawImage
            : ApiConstants.fileUrl(rawImage);
    return BrandModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      image: image,
      queuePosition: json['queue_position'] as int? ?? 0,
    );
  }
}
