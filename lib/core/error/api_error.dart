class APIError {
  final String message;
  final StackTrace? trace;

  APIError({required this.message, this.trace});

  factory APIError.fromJson(Map<String, dynamic> json, {StackTrace? trace}) {
    return APIError(message: json['err'], trace: trace);
  }

  @override
  String toString() {
    return 'APIError(message: $message, trace: $trace)';
  }
}
