/// Holds the authenticated user's identity for the current app session.
/// Set on login, cleared on logout.
class AppSession {
  AppSession._();

  static String? currentUsername;
  static String? currentRole;

  static void start(String username, String role) {
    currentUsername = username;
    currentRole = role;
  }

  static void clear() {
    currentUsername = null;
    currentRole = null;
  }
}
