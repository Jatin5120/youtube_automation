import 'dart:convert';

class ResponseModel {
  factory ResponseModel.error() => const ResponseModel(
        data: '',
        statusCode: 1000,
        hasError: true,
      );

  factory ResponseModel.message(
    String message, {
    bool isSuccess = false,
    int statusCode = 1000,
  }) =>
      ResponseModel(
        data: jsonEncode({'error': message}),
        hasError: !isSuccess,
        statusCode: statusCode,
      );

  factory ResponseModel.fromMap(Map<String, dynamic> map) => ResponseModel(
        data: map['data'] as String,
        hasError: map['hasError'] as bool,
        statusCode: map['statusCode'] != null ? map['statusCode'] as int : 1000,
      );

  factory ResponseModel.fromJson(String source) => ResponseModel.fromMap(json.decode(source) as Map<String, dynamic>);

  const ResponseModel({
    required this.data,
    required this.hasError,
    this.statusCode = 1000,
  });

  Map<String, dynamic> decode() => jsonDecode(data) as Map<String, dynamic>;

  final String data;
  final bool hasError;
  final int statusCode;

  ResponseModel copyWith({
    String? data,
    bool? hasError,
    int? statusCode,
  }) =>
      ResponseModel(
        data: data ?? this.data,
        hasError: hasError ?? this.hasError,
        statusCode: statusCode ?? this.statusCode,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'data': data,
        'hasError': hasError,
        'statusCode': statusCode,
      };

  String toJson() => json.encode(toMap());

  @override
  String toString() => 'IsmLiveResponseModel(data: $data, hasError: $hasError, statusCode: $statusCode)';

  @override
  bool operator ==(covariant ResponseModel other) {
    if (identical(this, other)) return true;

    return other.data == data && other.hasError == hasError && other.statusCode == statusCode;
  }

  @override
  int get hashCode => data.hashCode ^ hasError.hashCode ^ statusCode.hashCode;
}
