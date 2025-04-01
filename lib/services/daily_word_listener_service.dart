// lib/services/daily_word_listener_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that listens for daily word changes in the Firestore database
class DailyWordListenerService {
  // Singleton pattern
  static final DailyWordListenerService _instance = DailyWordListenerService._internal();
  factory DailyWordListenerService() => _instance;
  DailyWordListenerService._internal();

  // Core dependencies
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controller to broadcast word updates
  final StreamController<String> _dailyWordUpdateController = StreamController<String>.broadcast();
  Stream<String> get dailyWordUpdates => _dailyWordUpdateController.stream;

  // Subscription for the Firestore listener
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  // Status tracking
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? _currentDailyWordId;
  String? _currentWord;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get the current date formatted as YYYY-MM-DD
      final today = DateTime.now();
      _currentDailyWordId = _formatDateToId(today);

      // Start listening to the document for the current date
      _startListening(_currentDailyWordId!);

      // Schedule a check for date change at midnight
      _scheduleNextDayCheck();

      _isInitialized = true;

      if (kDebugMode) {
        print('DailyWordListenerService initialized. Listening for document: $_currentDailyWordId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing DailyWordListenerService: $e');
      }
    }
  }

  /// Start listening to the daily word document
  void _startListening(String documentId) {
    // Cancel any previous subscription
    _firestoreSubscription?.cancel();

    // Start a new subscription
    _firestoreSubscription = _firestore
        .collection('daily_words')
        .doc(documentId)
        .snapshots()
        .listen(_handleDocumentUpdate, onError: _handleListenError);

    if (kDebugMode) {
      print('Started listening to daily_words/$documentId');
    }
  }

  /// Handle document updates from Firestore
  void _handleDocumentUpdate(DocumentSnapshot snapshot) {
    try {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;

        if (data.containsKey('word')) {
          final newWord = data['word'] as String;

          // Only notify if the word has changed
          if (_currentWord != newWord) {
            _currentWord = newWord;
            _dailyWordUpdateController.add(newWord);

            if (kDebugMode) {
              print('New daily word detected: $newWord');
            }
          }
        }
      } else {
        if (kDebugMode) {
          print('Daily word document does not exist or is empty: ${snapshot.reference.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing daily word update: $e');
      }
    }
  }

  /// Handle errors from the Firestore listener
  void _handleListenError(Object error) {
    if (kDebugMode) {
      print('Error listening to daily word changes: $error');
    }

    // Try to reconnect after a delay
    Future.delayed(const Duration(minutes: 1), () {
      if (_currentDailyWordId != null) {
        _startListening(_currentDailyWordId!);
      }
    });
  }

  /// Check if the app has been open past midnight and update the listener
  Future<void> checkForDateChange() async {
    final now = DateTime.now();
    final todayId = _formatDateToId(now);

    // If the date has changed
    if (_currentDailyWordId != todayId) {
      if (kDebugMode) {
        print('Date changed from $_currentDailyWordId to $todayId. Updating listener.');
      }

      _currentDailyWordId = todayId;
      _startListening(todayId);

      // Reset current word to make sure we notify even if the new day has the same word
      _currentWord = null;

      // Schedule the next check
      _scheduleNextDayCheck();
    }
  }

  /// Schedule a check for date change at midnight
  void _scheduleNextDayCheck() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    // Add a small buffer (20 seconds) after midnight
    Future.delayed(timeUntilMidnight + const Duration(seconds: 20), () {
      checkForDateChange();
    });

    if (kDebugMode) {
      print('Next date change check scheduled in ${timeUntilMidnight.inHours} hours and ${timeUntilMidnight.inMinutes % 60} minutes');
    }
  }

  /// Force an immediate check for a new word
  Future<String?> forceCheck() async {
    try {
      if (_currentDailyWordId == null) {
        final now = DateTime.now();
        _currentDailyWordId = _formatDateToId(now);
      }

      final documentSnapshot = await _firestore
          .collection('daily_words')
          .doc(_currentDailyWordId)
          .get();

      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        final data = documentSnapshot.data()!;

        if (data.containsKey('word')) {
          final newWord = data['word'] as String;

          // Update current word
          _currentWord = newWord;

          return newWord;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during force check: $e');
      }
    }

    return null;
  }

  /// Format a DateTime to the daily word document ID format (YYYY-MM-DD)
  String _formatDateToId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Call this method when the app resumes from background
  Future<void> onAppResume() async {
    // First check if the date has changed
    await checkForDateChange();

    // Then force a check for the current word
    await forceCheck();
  }

  /// Clean up resources
  void dispose() {
    _firestoreSubscription?.cancel();
    _dailyWordUpdateController.close();
  }
}
