package id.pantoo.pos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pantoo.pos/subscription_clock")
            .setMethodCallHandler { call, result ->
                if (call.method == "read") {
                    try {
                        val boot = android.provider.Settings.Global.getInt(contentResolver, android.provider.Settings.Global.BOOT_COUNT)
                        result.success(mapOf("boot" to boot.toString(), "elapsed_ms" to android.os.SystemClock.elapsedRealtime()))
                    } catch (error: Exception) {
                        result.error("CLOCK_UNAVAILABLE", "Trusted clock unavailable", null)
                    }
                } else result.notImplemented()
            }
        // The emulator integration fixture uses Android's lifecycle API to
        // test actual background FCM delivery. No channel exists in release.
        if (BuildConfig.DEBUG) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pantoo.pos/push_qa")
                .setMethodCallHandler { call, result ->
                    if (call.method == "background" && call.arguments == "pantoo-pos-push-qa") {
                        result.success(moveTaskToBack(true))
                    } else {
                        result.notImplemented()
                    }
                }
        }
    }
}
