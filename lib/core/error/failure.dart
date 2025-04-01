import 'package:dio/dio.dart';

class Failure {
  final String message;
  final DioExceptionType? type;
  final StackTrace? trace;

  Failure({required this.message, this.type, this.trace});

  @override
  String toString() {
    return message;
  }
}
