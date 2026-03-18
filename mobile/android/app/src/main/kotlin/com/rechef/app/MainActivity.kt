package com.rechef.app

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
	private val shareImportChannel = "com.rechef.app/share_import_auth"
	private val shareImportPrefs = "share_import_auth"
	private val tokenKey = "firebase_id_token"
	private val apiBaseUrlKey = "api_base_url"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			shareImportChannel
		).setMethodCallHandler { call, result ->
			val prefs = getSharedPreferences(shareImportPrefs, MODE_PRIVATE)
			when (call.method) {
				"setAuthContext" -> {
					val token = call.argument<String>("token")
					val apiBaseUrl = call.argument<String>("apiBaseUrl")
					if (token.isNullOrBlank() || apiBaseUrl.isNullOrBlank()) {
						result.error("invalid_args", "token and apiBaseUrl are required", null)
						return@setMethodCallHandler
					}
					prefs.edit()
						.putString(tokenKey, token)
						.putString(apiBaseUrlKey, apiBaseUrl)
						.apply()
					result.success(null)
				}
				"clearAuthContext" -> {
					prefs.edit()
						.remove(tokenKey)
						.remove(apiBaseUrlKey)
						.apply()
					result.success(null)
				}
				else -> result.notImplemented()
			}
		}
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		// Keep latest share/deep-link intent available to Flutter plugins.
		setIntent(intent)
	}
}
