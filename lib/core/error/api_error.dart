class APIError {
  final String message;
  final StackTrace? trace;

  APIError({required this.message, this.trace});

  static APIError fromJson(Map<String, dynamic> json, {StackTrace? trace}) {
    return APIError(message: json['err'], trace: trace);
  }
}
