import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  static void handle(dynamic error) {
    String message = 'Bir hata oluştu';

    if (error.toString().contains('network')) {
      message = 'İnternet bağlantısı yok';
    } else if (error.toString().contains('permission')) {
      message = 'Bu işlem için yetkiniz yok';
    } else if (error.toString().contains('not-found')) {
      message = 'İstenen kaynak bulunamadı';
    }

    Get.snackbar(
      'Hata',
      message,
      backgroundColor: Colors.red.shade400,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
