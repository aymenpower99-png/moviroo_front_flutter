import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../services/auth_service/auth_service.dart';
import '../../../../../../services/passkey/passkey_service.dart';
import '../../../../../../theme/app_colors.dart';

class ActiveSessionsPage extends StatefulWidget {
  const ActiveSessionsPage({super.key});

  @override
  State<ActiveSessionsPage> createState() => _ActiveSessionsPageState();
}

class _ActiveSessionsPageState extends State<ActiveSessionsPage> {
  final _auth = AuthService();
  final _biometric = BiometricService();
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = false;
  bool _revoking = false;
  String? _error;

  // ── In-memory cache ─────────────────────────────────────────────────────────
  static List<Map<String, dynamic>>? _cachedSessions;

  @override
  void initState() {
    super.initState();

    // 1. Populate from cache synchronously — no spinner if we have data
    if (_cachedSessions != null) {
      _sessions = _cachedSessions!;
    } else {
      // No cache yet — show loader on first frame
      _loading = true;
    }

    // 2. Always refresh in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    // Only show a full-screen loader on the very first fetch when we have
    // nothing to display. If we already have cached sessions, refresh silently
    // in the background so the user never sees a blank screen.
    final shouldShowLoader = _cachedSessions == null;
    if (shouldShowLoader) {
      setState(() => _loading = true);
    }
    try {
      final sessions = await _auth.getSessions();
      _cachedSessions = sessions;
      if (mounted) setState(() => _sessions = sessions);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted && shouldShowLoader) {
        setState(() => _loading = false);
      }
    }
  }

  /// Clears the in-memory session cache. Call on logout or account switch.
  static void clearCache() => _cachedSessions = null;

  Future<void> _revokeAll() async {
    // Step-up auth: if biometric is enabled, require device biometric first
    final cached = _auth.getCachedUser();
    final hasBiometric = (cached?['passkeyEnabled'] as bool?) ?? false;
    if (hasBiometric) {
      final challenge = await _biometric.challenge(
        reason: 'Confirm your identity to sign out all devices.',
        purpose: 'revoke-sessions',
      );
      if (!challenge.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(challenge.errorMessage ?? 'Authentication cancelled.')),
          );
        }
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out all devices?'),
        content: const Text(
          'This will immediately sign you out of all devices including this one. '
          'You will need to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign out all'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _revoking = true);
    try {
      await _auth.revokeAllSessions();
      if (!mounted) return;
      // Tokens cleared — navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      setState(() => _revoking = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _removeSession(String id) async {
    try {
      await _auth.deleteSession(id);
      setState(() => _sessions.removeWhere((s) => s['id'] == id));
    } catch (_) {}
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('MMM d, y · HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _deviceLabel(Map<String, dynamic> s) {
    final raw = s['deviceLabel'] as String? ?? 'Unknown';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  IconData _deviceIcon(Map<String, dynamic> s) {
    final label = (s['deviceLabel'] as String? ?? '').toLowerCase();
    if (label.contains('ios') || label.contains('macos')) {
      return Icons.phone_iphone;
    }
    if (label.contains('android')) return Icons.phone_android;
    if (label.contains('windows') ||
        label.contains('linux') ||
        label.contains('macos')) {
      return Icons.computer;
    }
    return Icons.devices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Active Sessions',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These are the recent logins on your account. '
                    'If you see an unfamiliar device, sign out all devices immediately.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.primaryPurple,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sessions list
          if (_sessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No sessions found.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sessions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 64),
                itemBuilder: (_, i) => _SessionTile(
                  session: _sessions[i],
                  icon: _deviceIcon(_sessions[i]),
                  label: _deviceLabel(_sessions[i]),
                  ip: _sessions[i]['ipAddress'] as String? ?? '—',
                  createdAt: _formatDate(_sessions[i]['createdAt'] as String?),
                  lastSeen: _formatDate(_sessions[i]['lastSeenAt'] as String?),
                  onRemove: () => _removeSession(_sessions[i]['id'] as String),
                ),
              ),
            ),

          const SizedBox(height: 28),

          // Sign out all button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _revoking ? null : _revokeAll,
              icon: _revoking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded, size: 18),
              label: Text(_revoking ? 'Signing out…' : 'Sign out all devices'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  final IconData icon;
  final String label;
  final String ip;
  final String createdAt;
  final String lastSeen;
  final VoidCallback onRemove;

  const _SessionTile({
    required this.session,
    required this.icon,
    required this.label,
    required this.ip,
    required this.createdAt,
    required this.lastSeen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'IP: $ip',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  'Signed in: $createdAt',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Last seen: $lastSeen',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.grey,
            ),
            onPressed: onRemove,
            tooltip: 'Remove record',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
