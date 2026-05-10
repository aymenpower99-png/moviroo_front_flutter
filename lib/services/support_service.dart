import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/storage/token_storage.dart';

/// Support ticket category enum matching backend
enum SupportTicketCategory {
  account('account'),
  payment('payment'),
  ride('ride'),
  technical('technical'),
  other('other');

  final String value;
  const SupportTicketCategory(this.value);

  static SupportTicketCategory fromKey(String key) {
    switch (key) {
      case 'cat_ride_issue':
        return SupportTicketCategory.ride;
      case 'cat_payment':
        return SupportTicketCategory.payment;
      case 'cat_driver_complaint':
        return SupportTicketCategory.ride;
      case 'cat_app_bug':
        return SupportTicketCategory.technical;
      case 'cat_other':
      default:
        return SupportTicketCategory.other;
    }
  }
}

/// Support ticket status enum
enum SupportTicketStatus {
  open('open'),
  inProgress('in_progress'),
  waitingForUser('waiting_for_user'),
  resolved('resolved');

  final String value;
  const SupportTicketStatus(this.value);

  static SupportTicketStatus fromString(String value) {
    return SupportTicketStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SupportTicketStatus.open,
    );
  }
}

/// Support ticket model
class SupportTicket {
  final String id;
  final String subject;
  final String description;
  final SupportTicketStatus status;
  final SupportTicketCategory category;
  final String? rideId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool hasUnread;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.category,
    this.rideId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageAt,
    this.hasUnread = false,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      status: SupportTicketStatus.fromString(json['status'] ?? 'open'),
      category: SupportTicketCategory.values.firstWhere(
        (e) => e.value == json['category'],
        orElse: () => SupportTicketCategory.other,
      ),
      rideId: json['ride_id'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      hasUnread: json['has_unread'] ?? false,
    );
  }
}

/// Ticket message model
class TicketMessage {
  final String id;
  final String body;
  final String senderId;
  final String ticketId;
  final DateTime createdAt;
  final bool isFromAdmin;

  TicketMessage({
    required this.id,
    required this.body,
    required this.senderId,
    required this.ticketId,
    required this.createdAt,
    this.isFromAdmin = false,
  });

  factory TicketMessage.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    // Backend sends camelCase field names (senderId, ticketId, createdAt)
    // The 'sender' object may contain role info from enriched backend response
    final senderId = json['senderId'] ?? json['sender_id'] ?? '';
    final sender = json['sender'] as Map<String, dynamic>?;

    bool isFromAdmin;
    if (sender != null && sender['role'] != null) {
      // Use role from enriched backend response (preferred)
      isFromAdmin = sender['role'] == 'admin';
    } else {
      // Fallback: compare sender ID to current user
      isFromAdmin = senderId != currentUserId;
    }

    return TicketMessage(
      id: json['id'] ?? '',
      body: json['body'] ?? '',
      senderId: senderId,
      ticketId: json['ticketId'] ?? json['ticket_id'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isFromAdmin: isFromAdmin,
    );
  }
}

/// Service for support ticket API calls
class SupportService {
  final http.Client _client = http.Client();

  /// In-memory cache of the last fetched ticket list.
  /// Follows the same cache-first pattern used in ChatProvider.
  static List<SupportTicket>? cachedTickets;

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAccess();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Create a new support ticket
  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    required SupportTicketCategory category,
    String? rideId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'subject': subject,
        'description': description,
        'category': category.value,
        if (rideId != null) 'ride_id': rideId,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await _client
          .post(
            Uri.parse('${AppConfig.baseUrl}/support/tickets'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SupportTicket.fromJson(data);
      } else {
        throw Exception('Failed to create ticket: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  /// List user's tickets
  Future<List<SupportTicket>> listTickets({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('[SupportService] listTickets - fetching tickets...');
      final headers = await _getHeaders();
      final url =
          '${AppConfig.baseUrl}/support/tickets?page=$page&limit=$limit';
      print('[SupportService] listTickets - URL: $url');
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('[SupportService] listTickets - status: ${response.statusCode}');
      print('[SupportService] listTickets - body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
        final data = responseJson['data'] as List<dynamic>;
        print('[SupportService] listTickets - parsed ${data.length} tickets');
        final tickets = data
            .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
            .toList();
        cachedTickets = tickets; // update in-memory cache
        return tickets;
      } else {
        throw Exception('Failed to fetch tickets: ${response.statusCode}');
      }
    } catch (e) {
      print('[SupportService] listTickets - error: $e');
      throw Exception('Failed to fetch tickets: $e');
    }
  }

  /// Get a specific ticket with messages
  Future<Map<String, dynamic>> getTicket(String ticketId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .get(
            Uri.parse('${AppConfig.baseUrl}/support/tickets/$ticketId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[SupportService] getTicket - raw data: $data');
        final ticket = SupportTicket.fromJson(data);
        final currentUserId = await TokenStorage.getUserId();
        final messages =
            (data['messages'] as List<dynamic>?)
                ?.map(
                  (e) => TicketMessage.fromJson(
                    e as Map<String, dynamic>,
                    currentUserId ?? '',
                  ),
                )
                .toList() ??
            [];
        print(
          '[SupportService] getTicket - parsed messages count: ${messages.length}',
        );
        return {'ticket': ticket, 'messages': messages};
      } else {
        throw Exception('Failed to fetch ticket: ${response.statusCode}');
      }
    } catch (e) {
      print('[SupportService] getTicket - error: $e');
      throw Exception('Failed to fetch ticket: $e');
    }
  }

  /// Reply to a ticket
  Future<TicketMessage> replyToTicket({
    required String ticketId,
    required String body,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .post(
            Uri.parse('${AppConfig.baseUrl}/support/tickets/$ticketId/reply'),
            headers: headers,
            body: jsonEncode({'body': body}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final currentUserId = await TokenStorage.getUserId();
        return TicketMessage.fromJson(data, currentUserId ?? '');
      } else {
        throw Exception('Failed to reply: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to reply: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
