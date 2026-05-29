import 'package:flutter/foundation.dart';

import '../models/current_user_session.dart';

class CurrentUserProvider extends ChangeNotifier {
  CurrentUserSession _session = CurrentUserSession.empty;

  CurrentUserSession get session => _session;
  bool get isAuthenticated => _session.isAuthenticated;
  bool get isPaired => _session.isPaired;

  void setSession(CurrentUserSession session) {
    _session = session;
    notifyListeners();
  }
}
