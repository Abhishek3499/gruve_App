/// Generic cache data wrapper for type-safe serialization
class CacheData {
  final dynamic data;
  final String dataType; // 'map', 'list', 'nested', 'empty'
  final DateTime timestamp;

  CacheData({required this.data, required this.dataType})
    : timestamp = DateTime.now();

  /// Serialize to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'dataType': dataType,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Deserialize from JSON
  factory CacheData.fromJson(Map<String, dynamic> json) {
    return CacheData(
      data: json['data'],
      dataType: json['dataType'] ?? 'unknown',
    );
  }

  /// Create wrapper for Map responses
  factory CacheData.fromMap(Map<String, dynamic> data) {
    return CacheData(data: data, dataType: 'map');
  }

  /// Create wrapper for List responses
  factory CacheData.fromList(List<dynamic> data) {
    return CacheData(data: data, dataType: 'list');
  }

  /// Create wrapper for nested responses (Map with results/data array)
  factory CacheData.fromNested(Map<String, dynamic> data) {
    return CacheData(data: data, dataType: 'nested');
  }

  /// Create wrapper for empty responses
  factory CacheData.fromEmpty() {
    return CacheData(data: null, dataType: 'empty');
  }
}
