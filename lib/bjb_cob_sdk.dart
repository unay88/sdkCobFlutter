import 'dart:async';
import 'package:flutter/services.dart';

class BjbCobSdk {
  static const MethodChannel _channel = MethodChannel('bjb_cob_sdk');

  /// Start email verification flow
  static Future<SdkCobResult> startEmailVerification({
    required String phoneNumber,
    required String email,
    String? clientPlatform,
  }) async {
    try {
      final result = await _channel.invokeMethod('startEmailVerification', {
        'phoneNumber': phoneNumber,
        'email': email,
        'clientPlatform': clientPlatform,
      });
      // Handle result safely - convert to Map<String, dynamic>
      final Map<String, dynamic> resultMap = {};
      if (result is Map) {
        result.forEach((key, value) {
          resultMap[key.toString()] = value;
        });
      }
      return SdkCobResult.fromMap(resultMap);
    } on PlatformException catch (e) {
      return SdkCobResult.error(e.message ?? 'Unknown error');
    }
  }

  /// Launch KYC flow
  static Future<SdkCobResult> launchKYC() async {
    try {
      final result = await _channel.invokeMethod('launchKYC');
      // Handle result safely - convert to Map<String, dynamic>
      final Map<String, dynamic> resultMap = {};
      if (result is Map) {
        result.forEach((key, value) {
          resultMap[key.toString()] = value;
        });
      }
      return SdkCobResult.fromMap(resultMap);
    } on PlatformException catch (e) {
      return SdkCobResult.error(e.message ?? 'Unknown error');
    }
  }
}

/// Result from SDK COB operations
class SdkCobResult {
  final SdkCobStatus status;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  SdkCobResult._({
    required this.status,
    this.data,
    this.errorMessage,
  });

  factory SdkCobResult.success({Map<String, dynamic>? data}) {
    return SdkCobResult._(status: SdkCobStatus.success, data: data);
  }

  factory SdkCobResult.cancelled() {
    return SdkCobResult._(status: SdkCobStatus.cancelled);
  }

  factory SdkCobResult.error(String message) {
    return SdkCobResult._(
      status: SdkCobStatus.error,
      errorMessage: message,
    );
  }

  factory SdkCobResult.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status']?.toString() ?? 'error';
    final status = SdkCobStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => SdkCobStatus.error,
    );

    // Handle data safely
    Map<String, dynamic>? resultData;
    if (map['data'] != null) {
      if (map['data'] is Map) {
        resultData = {};
        (map['data'] as Map).forEach((key, value) {
          resultData![key.toString()] = value;
        });
      } else {
        resultData = null;
      }
    }

    return SdkCobResult._(
      status: status,
      data: resultData,
      errorMessage: map['errorMessage']?.toString(),
    );
  }

  bool get isSuccess => status == SdkCobStatus.success;
  bool get isCancelled => status == SdkCobStatus.cancelled;
  bool get isError => status == SdkCobStatus.error;
}

enum SdkCobStatus {
  success,
  cancelled,
  error,
}