package com.bjb.cob_sdk

import android.app.Activity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.bjb.cob.BjbCob
import java.util.Locale

class BjbCobSdkPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private var activity: Activity? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bjb_cob_sdk")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "startEmailVerification" -> {
        handleStartEmailVerification(call, result)
      }
      "launchKYC" -> {
        handleLaunchKYC(result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun handleStartEmailVerification(call: MethodCall, result: Result) {
    val phoneNumber = call.argument<String>("phoneNumber")
    val email = call.argument<String>("email")
    val clientPlatform = call.argument<String>("clientPlatform")
    
    if (phoneNumber == null || email == null) {
      result.error("INVALID_ARGUMENTS", "Missing phoneNumber or email", null)
      return
    }
    
    val currentActivity = activity
    if (currentActivity == null) {
      result.error("NO_ACTIVITY", "No activity available", null)
      return
    }
    
    try {
      // Force Indonesian locale
      val locale = Locale("id", "ID")
      Locale.setDefault(locale)
      val androidConfig = currentActivity.resources.configuration
      androidConfig.setLocale(locale)
      androidConfig.setLayoutDirection(locale)
      currentActivity.createConfigurationContext(androidConfig)
      currentActivity.window.decorView.layoutDirection = android.util.LayoutDirection.LTR
      
      // Use STAGING environment
      val sdkConfig = BjbCob.Config(
        environment = com.bjb.cob.core.config.Environment.Type.STAGING,
        apiBaseUrl = null,
        clientId = null,
        clientSecret = null
      )
      
      // Create callback
      val callback = object : BjbCob.CobCallback {
        override fun onSuccess() {
          currentActivity.runOnUiThread {
            result.success(mapOf(
              "status" to "success"
            ))
          }
        }
        
        override fun onError(message: String) {
          currentActivity.runOnUiThread {
            result.success(mapOf(
              "status" to "error",
              "errorMessage" to message
            ))
          }
        }
        
        override fun onCancelled() {
          currentActivity.runOnUiThread {
            result.success(mapOf(
              "status" to "cancelled"
            ))
          }
        }
      }
      
      // Start COB
      BjbCob.start(
        activity = currentActivity,
        phone = phoneNumber,
        email = email,
        config = sdkConfig,
        callback = callback,
        clientPlatform = clientPlatform ?: "1"
      )
    } catch (e: Exception) {
      result.error("LAUNCH_ERROR", "Failed to launch COB: ${e.message}", null)
    }
  }
  
  private fun handleLaunchKYC(result: Result) {
    result.error("NOT_IMPLEMENTED", "Direct KYC launch requires phone and email. Use startEmailVerification instead.", null)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
