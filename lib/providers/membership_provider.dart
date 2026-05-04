import 'package:flutter/foundation.dart';
import '../services/membership/membership_service.dart';

class MembershipProvider with ChangeNotifier {
  MembershipInfo? _info;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  MembershipInfo? get info => _info;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  /// Load membership info — skips API call if already cached (unless force=true).
  Future<void> loadMembership({bool force = false}) async {
    if (_hasLoaded && !force) {
      debugPrint('📦 [MembershipProvider] Using cached membership info');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📦 [MembershipProvider] Fetching membership info from API');
      _info = await MembershipService.getMembershipInfo();
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('📦 [MembershipProvider] Failed to load membership: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Force refresh from API.
  Future<void> refresh() => loadMembership(force: true);

  /// Invalidate cache so next [loadMembership] call re-fetches.
  void invalidate() {
    _hasLoaded = false;
  }
}
