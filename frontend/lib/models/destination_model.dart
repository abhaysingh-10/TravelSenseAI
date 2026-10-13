import 'package:flutter/material.dart';

class Destination {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double matchScore;
  final String reason;
  
  final double estimatedBudget;
  final int durationDays;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.matchScore,
    required this.reason,
    this.estimatedBudget = 15000.0,
    this.durationDays = 5,
  });

  String get localAssetPath {
    final slug = name.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'assets/images/destinations/$slug.jpg';
  }

  Widget buildImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      localAssetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, err, stack) => Image.asset(
            'assets/images/fallback_suitcase.jpg',
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, e, s) => Container(
              width: width,
              height: height,
              color: const Color(0xFF1E293B),
              child: const Center(
                child: Icon(Icons.landscape_rounded, color: Colors.white30, size: 48),
              ),
            ),
          ),
        );
      },
    );
  }

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id']?.toString() ?? json['name'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? 'A scenic travel destination.',
      imageUrl: json['image_url'] != null && json['image_url'].toString().startsWith('http')
          ? json['image_url']
          : 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.90,
      reason: json['reason'] ?? 'Curated for your travel style based on AI analysis.',
      estimatedBudget: (json['estimated_budget'] as num?)?.toDouble() ?? 25000.0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 4,
    );
  }
}
