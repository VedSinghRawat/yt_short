import 'package:dio/dio.dart';

class APIError {
  final String message;
  final StackTrace? trace;
  final DioExceptionType? dioExceptionType;

  APIError({required this.message, this.trace, this.dioExceptionType});

  factory APIError.fromJson(Map<String, dynamic> json, {StackTrace? trace}) {
    return APIError(message: json['err'], trace: trace);
  }

  @override
  String toString() {
    return 'APIError: $message, Trace: $trace';
  }
}
