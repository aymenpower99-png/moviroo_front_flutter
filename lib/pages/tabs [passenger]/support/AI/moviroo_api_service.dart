// ============================================================
// Moviroo AI Chatbot — Flutter API Service
// ============================================================
// Usage:
//   final api = MovirooApi();
//   final res = await api.chat("machkel fil paiement");
//   print(res.answer);
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

// ── Config ────────────────────────────────────────────────────
// const String _baseUrl = 'http://10.0.2.2:8000'; // Android emulator
// const String _baseUrl = 'http://localhost:8000'; // iOS simulator
// const String _baseUrl = 'http://192.168.1.17:800';
const String _baseUrl =
    'https://important-satisfy-sternness.ngrok-free.dev/api/chatbot';
// ── Models ────────────────────────────────────────────────────

class ChatResponse {
  final bool success;
  final String sessionId;
  final String message;
  final String answer;
  final double confidence;
  final String category;
  final String language;
  final String source; // direct_match | rag_llm | fallback
  final bool suggestTicket;
  final String? ticketId;

  ChatResponse({
    required this.success,
    required this.sessionId,
    required this.message,
    required this.answer,
    required this.confidence,
    required this.category,
    required this.language,
    required this.source,
    required this.suggestTicket,
    this.ticketId,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> j) => ChatResponse(
    success: j['success'] ?? false,
    sessionId: j['session_id'] ?? '',
    message: j['message'] ?? '',
    answer: j['answer'] ?? '',
    confidence: (j['confidence'] ?? 0.0).toDouble(),
    category: j['category'] ?? '',
    language: j['language'] ?? 'en',
    source: j['source'] ?? 'fallback',
    suggestTicket: j['suggest_ticket'] ?? false,
    ticketId: j['ticket_id'],
  );
}

class TicketResponse {
  final bool success;
  final String ticketId;
  final String question;
  final String? answer;
  final String? category;
  final String language;
  final String status;

  TicketResponse({
    required this.success,
    required this.ticketId,
    required this.question,
    this.answer,
    this.category,
    required this.language,
    required this.status,
  });

  factory TicketResponse.fromJson(Map<String, dynamic> j) => TicketResponse(
    success: j['success'] ?? true,
    ticketId: j['ticket_id'] ?? '',
    question: j['question'] ?? '',
    answer: j['answer'],
    category: j['category'],
    language: j['language'] ?? 'en',
    status: j['status'] ?? 'open',
  );
}

class FeedbackResponse {
  final bool success;
  final String message;

  FeedbackResponse({required this.success, required this.message});

  factory FeedbackResponse.fromJson(Map<String, dynamic> j) => FeedbackResponse(
    success: j['success'] ?? false,
    message: j['message'] ?? '',
  );
}

class HealthResponse {
  final bool success;
  final String status;
  final int faissVectors;
  final String version;

  HealthResponse({
    required this.success,
    required this.status,
    required this.faissVectors,
    required this.version,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> j) => HealthResponse(
    success: j['success'] ?? false,
    status: j['status'] ?? 'unknown',
    faissVectors: j['faiss_vectors'] ?? 0,
    version: j['version'] ?? '',
  );
}

// ── API Service ───────────────────────────────────────────────

class MovirooApi {
  final String baseUrl;
  final _uuid = const Uuid();
  late final String _sessionId;

  static const Duration _timeout = Duration(seconds: 30);

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  MovirooApi({this.baseUrl = _baseUrl}) {
    _sessionId = _uuid.v4();
  }

  // ── Helpers ──────────────────────────────────────────────────

  Uri _url(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(_url(path), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
      throw ApiException('HTTP ${res.statusCode}', res.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http
          .get(_url(path), headers: _headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
      throw ApiException('HTTP ${res.statusCode}', res.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .patch(_url(path), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
      throw ApiException('HTTP ${res.statusCode}', res.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  // ── Public Methods ────────────────────────────────────────────

  /// Send a message to the chatbot
  /// Returns [ChatResponse] with answer + confidence + suggest_ticket flag
  Future<ChatResponse> chat(String message) async {
    final data = await _post('/chat', {
      'message': message,
      'session_id': _sessionId,
    });
    return ChatResponse.fromJson(data);
  }

  /// Create a support ticket manually
  Future<TicketResponse> createTicket({
    required String question,
    String? category,
    String language = 'en',
  }) async {
    final data = await _post('/tickets', {
      'question': question,
      'session_id': _sessionId,
      if (category != null) 'category': category,
      'language': language,
    });
    return TicketResponse.fromJson(data);
  }

  /// Get a ticket by ID
  Future<TicketResponse> getTicket(String ticketId) async {
    final data = await _get('/tickets/$ticketId');
    return TicketResponse.fromJson(data);
  }

  /// Submit feedback for a conversation
  Future<FeedbackResponse> submitFeedback({
    required int rating,
    String? ticketId,
    bool? helpful,
    String? comment,
  }) async {
    final data = await _post('/feedback', {
      'rating': rating,
      'session_id': _sessionId,
      if (ticketId != null) 'ticket_id': ticketId,
      if (helpful != null) 'helpful': helpful,
      if (comment != null) 'comment': comment,
    });
    return FeedbackResponse.fromJson(data);
  }

  /// Check API health — call this on app start
  Future<HealthResponse> health() async {
    final data = await _get('/health');
    return HealthResponse.fromJson(data);
  }
}

// ── Exception ─────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
