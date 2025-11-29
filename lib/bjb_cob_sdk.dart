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
      return SdkCobResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      return SdkCobResult.error(e.message ?? 'Unknown error');
    }
  }

  /// Launch KYC flow
  static Future<SdkCobResult> launchKYC() async {
    try {
      final result = await _channel.invokeMethod('launchKYC');
      return SdkCobResult.fromMap(Map<String, dynamic>.from(result));
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
    final statusStr = map['status'] as String;
    final status = SdkCobStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => SdkCobStatus.error,
    );

    return SdkCobResult._(
      status: status,
      data: map['data'] as Map<String, dynamic>?,
      errorMessage: map['errorMessage'] as String?,
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