package com.example.flu2

import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "rindegasto/vibrate"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"vibrate" -> {
					val duration = (call.argument<Int>("duration") ?: 80).toLong()
					vibrate(duration)
					result.success(null)
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun vibrate(duration: Long) {
		val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
		vibrator?.let {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
				it.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE))
			} else {
				@Suppress("DEPRECATION")
				it.vibrate(duration)
			}
		}
	}
}
