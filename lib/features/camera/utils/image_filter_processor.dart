import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';

class ImageFilterProcessor {
  static Future<File> applyColorMatrixToImage(File file, List<double> matrix) async {
    try {
      // Read image bytes
      final Uint8List imageBytes = await file.readAsBytes();
      
      // Decode image to get codec
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      
      // Create canvas for drawing
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      
      // Create paint with color matrix filter
      final ui.Paint paint = ui.Paint()
        ..colorFilter = ui.ColorFilter.matrix(matrix);
      
      // Draw the image with filter
      canvas.drawImage(originalImage, Offset.zero, paint);
      
      // End recording and get picture
      final ui.Picture picture = recorder.endRecording();
      
      // Convert to image
      final ui.Image filteredImage = await picture.toImage(
        originalImage.width,
        originalImage.height,
      );
      
      // Convert to bytes
      final ByteData? byteData = await filteredImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData == null) {
        throw Exception('Failed to convert filtered image to bytes');
      }
      
      // Create temporary file with filtered image
      final String tempPath = '${file.parent.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.png';
      final File filteredFile = File(tempPath);
      await filteredFile.writeAsBytes(byteData.buffer.asUint8List());
      
      // Clean up resources
      picture.dispose();
      filteredImage.dispose();
      originalImage.dispose();
      
      return filteredFile;
    } catch (e) {
      debugPrint('Error applying color matrix: $e');
      // Return original file if processing fails
      return file;
    }
  }
  
  static Future<File> resizeImageIfNeeded(File file, {int maxWidth = 1920, int maxHeight = 1920}) async {
    try {
      final Uint8List imageBytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;
      
      // Check if resize is needed
      if (originalWidth <= maxWidth && originalHeight <= maxHeight) {
        originalImage.dispose();
        return file;
      }
      
      // Calculate new dimensions maintaining aspect ratio
      double aspectRatio = originalWidth / originalHeight;
      int newWidth = originalWidth;
      int newHeight = originalHeight;
      
      if (originalWidth > maxWidth) {
        newWidth = maxWidth;
        newHeight = (maxWidth / aspectRatio).round();
      }
      
      if (newHeight > maxHeight) {
        newHeight = maxHeight;
        newWidth = (maxHeight * aspectRatio).round();
      }
      
      // Create resized image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      
      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        Paint(),
      );
      
      final ui.Picture picture = recorder.endRecording();
      final ui.Image resizedImage = await picture.toImage(newWidth, newHeight);
      
      final ByteData? byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData == null) {
        throw Exception('Failed to convert resized image to bytes');
      }
      
      // Create temporary file with resized image
      final String tempPath = '${file.parent.path}/resized_${DateTime.now().millisecondsSinceEpoch}.png';
      final File resizedFile = File(tempPath);
      await resizedFile.writeAsBytes(byteData.buffer.asUint8List());
      
      // Clean up resources
      picture.dispose();
      resizedImage.dispose();
      originalImage.dispose();
      
      return resizedFile;
    } catch (e) {
      debugPrint('Error resizing image: $e');
      // Return original file if resizing fails
      return file;
    }
  }

  static Future<File> compressImageForUpload(File file, {int maxFileSizeKB = 500}) async {
    try {
      debugPrint('🗜️ Starting image compression...');
      
      final int originalSizeKB = await file.length() ~/ 1024;
      debugPrint('📏 Original file size: ${originalSizeKB}KB');
      
      // If file is already small enough, return it
      if (originalSizeKB <= maxFileSizeKB) {
        debugPrint('✅ File size is acceptable, no compression needed');
        return file;
      }
      
      // First try resizing to smaller dimensions
      File compressedFile = await resizeImageIfNeeded(file, maxWidth: 1080, maxHeight: 1080);
      int compressedSizeKB = await compressedFile.length() ~/ 1024;
      debugPrint('📏 After resize: ${compressedSizeKB}KB');
      
      // If still too large, try even smaller dimensions
      if (compressedSizeKB > maxFileSizeKB) {
        compressedFile = await resizeImageIfNeeded(file, maxWidth: 800, maxHeight: 800);
        compressedSizeKB = await compressedFile.length() ~/ 1024;
        debugPrint('📏 After further resize: ${compressedSizeKB}KB');
      }
      
      // If still too large, try very small dimensions
      if (compressedSizeKB > maxFileSizeKB) {
        compressedFile = await resizeImageIfNeeded(file, maxWidth: 600, maxHeight: 600);
        compressedSizeKB = await compressedFile.length() ~/ 1024;
        debugPrint('📏 After aggressive resize: ${compressedSizeKB}KB');
      }
      
      debugPrint('✅ Compression complete. Final size: ${compressedSizeKB}KB');
      
      // Clean up original file if it's different from compressed file
      if (compressedFile.path != file.path) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('⚠️ Could not delete original file: $e');
        }
      }
      
      return compressedFile;
    } catch (e) {
      debugPrint('❌ Error compressing image: $e');
      // Return original file if compression fails
      return file;
    }
  }
}
