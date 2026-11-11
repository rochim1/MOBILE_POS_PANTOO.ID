package id.pantoo.pos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
