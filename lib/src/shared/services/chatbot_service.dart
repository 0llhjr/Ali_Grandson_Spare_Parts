// ============================================================
// chatbot_service.dart — AI Chatbot HTTP Client
// ============================================================
// Handles all communication with the external chatbot server.
//
// Two-step flow (from FRONTEND_INTEGRATION.md):
//   Step 1 — POST /chat with the user's question + session_id.
//            Server returns either:
//              • status:"answered"   → answer string + session_id.
//              • status:"data_needed" → ref_code + what DB data
//                                       to fetch locally + session_id.
//   Step 2 — (only if data_needed)
//            Query the local SQLite database using the
//            data_request info, then POST /chat/respond with
//            { ref_code, data } to get the final answer + session_id.
//
// Session context (CHANGELOG_conversation_context.md):
//   • The server keeps the last 3 Q&A pairs as context per session.
//   • session_id is null on the first message; the server creates
//     one and returns it. Every subsequent message sends it back so
//     the server can continue the same conversation thread.
//   • Sessions expire after 30 minutes of inactivity.
//   • Call resetSession() to start a fresh conversation (e.g. "New Chat").
//
// Config (set in .env):
//   CHATBOT_URL     — base URL of the chatbot server
//   CHATBOT_API_KEY — secret key sent in X-API-Key header
// ============================================================

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

/// Sends questions to the chatbot API, maintains conversation context
/// via session_id, and resolves any live-data requests against the
/// local SQLite database automatically.
class ChatbotService {
  static String get _baseUrl =>
      dotenv.env['CHATBOT_URL'] ?? 'http://localhost:8000';

  static String get _apiKey => dotenv.env['CHATBOT_API_KEY'] ?? '';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': _apiKey,
      };

  // ── Session state ───────────────────────────────────────────

  /// Holds the current conversation session ID returned by the server.
  /// Null on the first message of a new chat; populated after the first
  /// response and sent with every subsequent request so the server can
  /// maintain conversation context (last 3 Q&A pairs).
  static String? _sessionId;

  /// Clears the stored session ID so the next [ask] call starts a
  /// brand-new conversation thread with no prior context.
  /// Call this when the user taps "New Chat".
  static void resetSession() => _sessionId = null;

  // ── Public API ──────────────────────────────────────────────

  /// Sends [question] to the chatbot and returns the final answer string.
  ///
  /// [username] is the logged-in customer's username — used to scope
  /// any database queries to that user's data only (orders, cart).
  /// Pass null when the user is not logged in.
  static Future<String> ask(String question, {String? username}) async {
    try {
      // ── Step 1: POST /chat ──────────────────────────────────
      final res1 = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: _headers,
            body: jsonEncode({
              'question': question,
              // null on first message; server creates + returns a session_id.
              // Subsequent messages send it back to resume conversation context.
              'session_id': _sessionId,
            }),
          )
          .timeout(const Duration(seconds: 90));

      final error1 = _checkHttpError(res1.statusCode);
      if (error1 != null) return error1;

      final body1 = jsonDecode(res1.body) as Map<String, dynamic>;

      // Always save the session_id the server returns.
      _sessionId = body1['session_id'] as String?;

      // Server answered directly — we're done.
      if (body1['status'] == 'answered') {
        return body1['answer'] as String? ?? 'No answer returned.';
      }

      // Server needs live data from the local database.
      if (body1['status'] == 'data_needed') {
        final refCode = body1['ref_code'] as String;
        final dataRequest = Map<String, dynamic>.from(
          body1['data_request'] as Map,
        );

        // ── Step 2: Query local SQLite ──────────────────────
        final dbData = await _queryLocalDb(dataRequest, username);

        // ── Step 3: POST /chat/respond ──────────────────────
        final res2 = await http
            .post(
              Uri.parse('$_baseUrl/chat/respond'),
              headers: _headers,
              body: jsonEncode({'ref_code': refCode, 'data': dbData}),
            )
            .timeout(const Duration(seconds: 90));

        if (res2.statusCode == 404) {
          return 'The session expired while fetching your data. Please ask again.';
        }
        final error2 = _checkHttpError(res2.statusCode);
        if (error2 != null) return error2;

        final body2 = jsonDecode(res2.body) as Map<String, dynamic>;

        // Save session_id from the respond endpoint as well.
        _sessionId = body2['session_id'] as String? ?? _sessionId;

        return body2['answer'] as String? ?? 'No answer returned.';
      }

      return 'Unexpected response from the assistant. Please try again.';
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return 'The assistant took too long to respond. Please try again.';
      }
      return 'Could not reach the assistant. Please check your internet connection.';
    }
  }

  // ── Private helpers ─────────────────────────────────────────

  /// Translates HTTP error codes into user-friendly messages.
  /// Returns null when the status code is successful (2xx).
  static String? _checkHttpError(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return null;
    switch (statusCode) {
      case 403:
        return 'Authentication error. Please check the chatbot configuration.';
      case 429:
        return 'The assistant is busy right now. Please try again in a moment.';
      case 502:
        return 'The assistant service is temporarily unavailable.';
      case 504:
        return 'The assistant timed out. Please try again.';
      default:
        return 'Something went wrong (HTTP $statusCode). Please try again.';
    }
  }

  /// Executes a safe, scoped SQLite query based on the chatbot's
  /// [dataRequest] object:
  ///   • table         — which SQLite table to query
  ///   • fields_needed — which columns to SELECT
  ///   • filters       — WHERE clause key/value pairs
  ///
  /// Security rules enforced here:
  ///   • Only whitelisted tables are allowed.
  ///   • For user-private tables (orders, cart, users), the current
  ///     [username] is always injected into the WHERE clause so the
  ///     chatbot can never read another customer's data.
  ///   • If [username] is null and the table is private, returns [].
  static Future<List<Map<String, dynamic>>> _queryLocalDb(
    Map<String, dynamic> dataRequest,
    String? username,
  ) async {
    const allowedTables = {
      'spare_part_products',
      'orders',
      'order_items',
      'faqs',
      'users',
      'cart',
    };
    const privateTables = {'orders', 'cart', 'users'};

    final table = dataRequest['table'] as String?;
    if (table == null || !allowedTables.contains(table)) return [];

    if (privateTables.contains(table) && username == null) return [];

    final List<String>? columns =
        (dataRequest['fields_needed'] as List?)?.cast<String>();

    final Map<String, dynamic> filters = dataRequest['filters'] != null
        ? Map<String, dynamic>.from(dataRequest['filters'] as Map)
        : {};

    // Enforce user ownership on private tables regardless of what
    // filters the chatbot server requested.
    if (username != null) {
      if (table == 'users') {
        filters['username'] = username;
      } else if (table == 'orders' || table == 'cart') {
        filters['user_username'] = username;
      }
    }

    String? whereClause;
    List<dynamic> whereArgs = [];
    if (filters.isNotEmpty) {
      whereClause = filters.keys.map((k) => '$k = ?').join(' AND ');
      whereArgs = filters.values.toList();
    }

    final db = await DatabaseHelper.instance.database;
    return await db.query(
      table,
      columns: columns,
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      limit: 50,
    );
  }
}
