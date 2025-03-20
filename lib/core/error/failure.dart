import 'package:dio/dio.dart';

class Failure {
  final String message;
  final DioExceptionType? type;

  Failure({required this.message, this.type});

  @override
  String toString() {
    return 'Failure(message: $message)';
  }
}
