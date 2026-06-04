import 'package:equatable/equatable.dart';

/// GPS Route Point Model
class RoutePoint extends Equatable {
  final double lat;
  final double lng;
  final DateTime timestamp;

  const RoutePoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  /// Convert to JSON for backend API
  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  List<Object?> get props => [lat, lng, timestamp];
}
