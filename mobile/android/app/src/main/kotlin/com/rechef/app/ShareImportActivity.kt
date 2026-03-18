package com.rechef.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Base64
import android.widget.Toast
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.regex.Pattern

class ShareImportActivity : Activity() {
	private val shareImportPrefs = "share_import_auth"
	private val tokenKey = "firebase_id_token"
	private val apiBaseUrlKey = "api_base_url"
	private val parseEndpoint = "/api/contents/parse"
	private val httpUrlRegex = Pattern.compile("https?://[^\\s]+", Pattern.CASE_INSENSITIVE)
	private val maxImageBytes = 8 * 1024 * 1024

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		handleShareIntent(intent)
	}

	private fun handleShareIntent(intent: Intent?) {
		if (intent == null) {
			finish()
			return
		}
		val prefs = getSharedPreferences(shareImportPrefs, MODE_PRIVATE)
		val token = prefs.getString(tokenKey, null)
		val apiBaseUrl = prefs.getString(apiBaseUrlKey, null)
		if (token.isNullOrBlank() || apiBaseUrl.isNullOrBlank()) {
			Toast.makeText(this, "Open Rechef and sign in first", Toast.LENGTH_SHORT).show()
			finish()
			return
		}

		val payload = when (intent.action) {
			Intent.ACTION_SEND -> payloadForSingleSend(intent)
			Intent.ACTION_SEND_MULTIPLE -> null
			else -> null
		}
		if (payload == null) {
			Toast.makeText(this, "Could not read shared content", Toast.LENGTH_SHORT).show()
			finish()
			return
		}

		postImportRequest(apiBaseUrl, token, payload)
	}

	private fun payloadForSingleSend(intent: Intent): JSONObject? {
		val type = intent.type?.lowercase()
		if (type != null && type.startsWith("text/")) {
			val text = intent.getStringExtra(Intent.EXTRA_TEXT)
				?: intent.getStringExtra(Intent.EXTRA_SUBJECT)
			val url = extractFirstHttpUrl(text)
			return if (url != null) JSONObject().put("url", url) else null
		}
		if (type != null && type.startsWith("image/")) {
			val imageUri = getImageUriExtra(intent)
			val imageBase64 = imageUri?.let { loadImageAsBase64(it) }
			return if (imageBase64 != null) JSONObject().put("imageBase64", imageBase64) else null
		}
		val fallbackText = intent.getStringExtra(Intent.EXTRA_TEXT)
		val fallbackUrl = extractFirstHttpUrl(fallbackText)
		return if (fallbackUrl != null) JSONObject().put("url", fallbackUrl) else null
	}

	@Suppress("DEPRECATION")
	private fun getImageUriExtra(intent: Intent): Uri? {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
		} else {
			intent.getParcelableExtra(Intent.EXTRA_STREAM)
		}
	}

	private fun extractFirstHttpUrl(text: String?): String? {
		if (text.isNullOrBlank()) return null
		val directUri = runCatching { Uri.parse(text.trim()) }.getOrNull()
		if (directUri != null && (directUri.scheme == "http" || directUri.scheme == "https")) {
			return text.trim()
		}
		val matcher = httpUrlRegex.matcher(text)
		return if (matcher.find()) matcher.group() else null
	}

	private fun loadImageAsBase64(uri: Uri): String? {
		return runCatching {
			contentResolver.openInputStream(uri)?.use { input ->
				val output = ByteArrayOutputStream()
				val buffer = ByteArray(16 * 1024)
				var totalRead = 0
				while (true) {
					val read = input.read(buffer)
					if (read <= 0) break
					totalRead += read
					if (totalRead > maxImageBytes) {
						return null
					}
					output.write(buffer, 0, read)
				}
				Base64.encodeToString(output.toByteArray(), Base64.NO_WRAP)
			}
		}.getOrNull()
	}

	private fun postImportRequest(apiBaseUrl: String, token: String, payload: JSONObject) {
		Thread {
			val resultMessage = runCatching {
				val endpoint = "${apiBaseUrl.trimEnd('/')}$parseEndpoint"
				val connection = URL(endpoint).openConnection() as HttpURLConnection
				connection.requestMethod = "POST"
				connection.setRequestProperty("Content-Type", "application/json")
				connection.setRequestProperty("Authorization", "Bearer $token")
				connection.connectTimeout = 15000
				connection.readTimeout = 15000
				connection.doOutput = true
				OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
					writer.write(payload.toString())
				}
				val status = connection.responseCode
				connection.disconnect()
				if (status == 202) {
					"Done - open Rechef to view when ready"
				} else {
					"Import failed"
				}
			}.getOrElse {
				"Import failed"
			}

			runOnUiThread {
				Toast.makeText(this, resultMessage, Toast.LENGTH_SHORT).show()
				finish()
			}
		}.start()
	}
}
