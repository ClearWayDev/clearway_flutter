class AppInfo {
  final String backendUrl;

  AppInfo({required this.backendUrl});

  AppInfo copyWith({String? backendUrl}) {
    return AppInfo(backendUrl: backendUrl ?? this.backendUrl);
  }
}
