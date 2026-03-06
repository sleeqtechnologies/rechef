package com.rechef.app

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		// Keep latest share/deep-link intent available to Flutter plugins.
		setIntent(intent)
	}
}
