package app.memryth.android

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var methodChannel: MethodChannel? = null
    private var pendingSharedText: String? = null
    private var pendingQuickAdd = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "app.memryth.android/share"
        )
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "consumeInitialText") {
                val text = pendingSharedText ?: extractSharedText(intent)
                pendingSharedText = null
                result.success(text)
            } else if (call.method == "consumeQuickAdd") {
                val shouldOpen = pendingQuickAdd || isQuickAdd(intent)
                pendingQuickAdd = false
                result.success(shouldOpen)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        if (isQuickAdd(intent)) {
            val channel = methodChannel
            if (channel == null) {
                pendingQuickAdd = true
            } else {
                channel.invokeMethod("quickAdd", null)
            }
            return
        }

        val text = extractSharedText(intent) ?: return
        val channel = methodChannel
        if (channel == null) {
            pendingSharedText = text
        } else {
            channel.invokeMethod("sharedText", text)
        }
    }

    private fun extractSharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) {
            return null
        }
        if (intent.type != "text/plain") {
            return null
        }
        return intent.getStringExtra(Intent.EXTRA_TEXT)?.trim()
    }

    private fun isQuickAdd(intent: Intent?): Boolean {
        return intent?.action == "app.memryth.android.action.QUICK_ADD"
    }
}
