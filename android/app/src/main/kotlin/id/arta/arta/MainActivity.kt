package id.arta.arta

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    private var security: AppSecurityBridge? = null
    private var photos: ReceiptPickerBridge? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        security = AppSecurityBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        photos = ReceiptPickerBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "id.arta.arta/storage")
            .setMethodCallHandler { call, result ->
                if (call.method == "getApplicationSupportDirectory") {
                    try {
                        result.success(applicationContext.filesDir.absolutePath)
                    } catch (error: Exception) {
                        result.error("STORAGE_DIRECTORY_UNAVAILABLE", error.javaClass.simpleName, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    @Deprecated("Android activity result callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (photos?.onResult(requestCode, resultCode, data) != true) super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() { security?.close(); photos?.close(); super.onDestroy() }
    override fun onPause() { security?.invalidate(); super.onPause() }
}
