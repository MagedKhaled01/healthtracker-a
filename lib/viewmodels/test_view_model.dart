import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/test_model.dart';
import '../data/repositories/test_repository.dart';
import '../services/storage_service.dart';

import 'mixins/selection_view_model_mixin.dart';

class TestViewModel extends ChangeNotifier with SelectionViewModelMixin<String> {
  final TestRepository _repository;
  final StorageService _storage;
  final FirebaseAuth _auth;

  TestViewModel({TestRepository? repository, StorageService? storage, FirebaseAuth? auth})
      : _repository = repository ?? TestRepository(),
        _storage = storage ?? StorageService(),
        _auth = auth ?? FirebaseAuth.instance;

  List<TestModel> _allTests = [];
  List<TestModel> _filteredTests = [];

  List<TestModel> get tests => _filteredTests;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<TestModel>>? _testsSubscription;

  // Search Query
  String _searchQuery = '';

  void loadTests() {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _testsSubscription?.cancel();
      _testsSubscription = _repository.getUserTests(user.uid).listen(
        (tests) {
          _allTests = tests;
          _applyFilters(); 
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchTests(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredTests = List.from(_allTests);
    } else {
      _filteredTests = _allTests.where((test) {
        return test.testName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Future<String> _uploadAttachment(String userId, String testId, String filePath) async {
    return await _storage.uploadTestAttachment(
      userId: userId, 
      testId: testId, 
      filePath: filePath
    );
  }

  Future<bool> addTest({
    required String testName,
    required DateTime testDate,
    String? result,
    String? notes,
    String? attachmentUrl, 
    String? filePath,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Generate ID client-side to ensure storage path validity
      final String testId = const Uuid().v4();
      String? finalAttachmentUrl = attachmentUrl;
      
      // 2. Upload if file provided (Strict Flow)
      if (filePath != null) {
        try {
          finalAttachmentUrl = await _uploadAttachment(user.uid, testId, filePath);
        } catch (e) {
          _errorMessage = "Upload failed: ${e.toString()}";
          _isLoading = false;
          notifyListeners();
          return false; // Prevent saving if upload fails
        }
      }

      final newTest = TestModel(
        id: testId, // Use the pre-generated ID
        userId: user.uid,
        testName: testName,
        testDate: testDate,
        result: result?.isEmpty == true ? null : result,
        notes: notes?.isEmpty == true ? null : notes,
        attachmentUrl: finalAttachmentUrl,
        createdAt: DateTime.now(),
      );

      // 3. Save to Firestore using the known ID
      await _repository.addTest(newTest);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Save Error: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTest({
    required String id,
    required String testName,
    required DateTime testDate,
    String? result,
    String? notes,
    String? attachmentUrl,
    String? filePath,
    required DateTime createdAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      String? finalAttachmentUrl = attachmentUrl;

      // Upload if new file provided
      if (filePath != null) {
        try {
          // Use existing ID for update logic
          finalAttachmentUrl = await _uploadAttachment(user.uid, id, filePath);
        } catch (e) {
          _errorMessage = "Upload failed: ${e.toString()}";
           _isLoading = false;
           notifyListeners();
           return false;
        }
      }

      final updatedTest = TestModel(
        id: id,
        userId: user.uid,
        testName: testName,
        testDate: testDate,
        result: result?.isEmpty == true ? null : result,
        notes: notes?.isEmpty == true ? null : notes,
        attachmentUrl: finalAttachmentUrl,
        createdAt: createdAt,
      );

      await _repository.updateTest(updatedTest);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Update Error: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteTest(String testId, String? attachmentUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _repository.deleteTest(user.uid, testId);
      if (attachmentUrl != null) {
        await _storage.deleteFile(attachmentUrl);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _testsSubscription?.cancel();
    super.dispose();
  }
}
