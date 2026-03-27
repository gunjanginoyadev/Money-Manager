enum AuthMode {
  undecided,
  offline,
  anonymous,
  email,
}

extension AuthModeX on AuthMode {
  String get value => name;

  static AuthMode fromValue(String? value) {
    if (value == null) return AuthMode.undecided;
    if (value == 'offline' || value == 'anonymous') {
      return AuthMode.undecided;
    }
    return AuthMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AuthMode.undecided,
    );
  }
}
