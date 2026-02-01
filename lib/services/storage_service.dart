import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage and returns the download URL.
  /// 
  /// Strictly follows the requested flow:
  /// ref -> putFile -> await -> check state -> getDownloadURL
  ///
  /// Path: users/{userId}/tests/{testId}/attachment.{ext}
  Future<String> uploadTestAttachment({
    required String userId, 
    required String testId,
    required String filePath, 
  }) async {
    try {
      final File file = File(filePath);
      if (!file.existsSync()) {
        throw Exception("File not found at path: $filePath");
      }

      // 1. Determine Extension
      String extension = "";
      final String originalName = filePath.split(Platform.pathSeparator).last;
      if (originalName.contains('.')) {
        extension = originalName.split('.').last;
      }
      // Fallback or sanitize extension
      if (extension.isEmpty) extension = "bin";

      // 2. Construct Strict Path (Fixed filename 'attachment')
      final String storagePath = 'users/$userId/tests/$testId/attachment.$extension';
      
      debugPrint("[Storage] Starting upload...");
      debugPrint("[Storage] Local File: $filePath");
      debugPrint("[Storage] Target Path: $storagePath");

      // 3. Create Reference
      final Reference ref = _storage.ref().child(storagePath);

      // 4. Upload File
      final UploadTask uploadTask = ref.putFile(file);
      
      // 5. Await Completion
      final TaskSnapshot snapshot = await uploadTask;
      
      debugPrint("[Storage] Upload finished. State: ${snapshot.state}");
      debugPrint("[Storage] Bytes transferred: ${snapshot.bytesTransferred} / ${snapshot.totalBytes}");

      // 6. Check Success
      if (snapshot.state == TaskState.success) {
        // 7. Get Download URL from SNAPSHOT REF (Guaranteed same object)
        debugPrint("[Storage] Retrieving Download URL...");
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint("[Storage] URL Success: $downloadUrl");
        return downloadUrl;
      } else {
        throw Exception("Upload failed with state: ${snapshot.state}");
      }
    } on FirebaseException catch (e) {
      debugPrint('[Storage] Firebase Error: ${e.code} - ${e.message}');
      debugPrint('[Storage] Request ID: ${e.stackTrace}');
      throw Exception('Storage Error: ${e.message}');
    } catch (e) {
      debugPrint('[Storage] General Error: $e');
      throw Exception('Upload failed: $e');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    if (fileUrl.isEmpty) return;
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      debugPrint("[Storage] File deleted: $fileUrl");
    } catch (e) {
      debugPrint('[Storage] Error deleting file: $e');
    }
  }
}
