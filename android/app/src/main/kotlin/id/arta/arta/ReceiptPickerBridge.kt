package id.arta.arta

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import kotlin.math.max

class ReceiptPickerBridge(private val activity: FlutterActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "id.arta.arta/photos")
    private val worker = Executors.newSingleThreadExecutor()
    private var pending: MethodChannel.Result? = null
    private val request = 4607
    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "pickReceipt") result.notImplemented()
            else if (pending != null) result.error("PICKER_BUSY", "Pemilih foto masih terbuka.", null)
            else {
                pending = result
                try {
                    val photo = Intent(MediaStore.ACTION_PICK_IMAGES).setType("image/*")
                    val intent = if (photo.resolveActivity(activity.packageManager) != null) photo
                        else Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("image/*")
                    activity.startActivityForResult(intent, request)
                } catch (_: Exception) { pending = null; result.error("PICKER_UNAVAILABLE", "Pemilih foto belum tersedia.", null) }
            }
        }
    }
    fun onResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != request) return false
        val result = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) { result.success(null); return true }
        worker.execute {
            try {
                val resolver = activity.contentResolver
                val bitmap: Bitmap = if (Build.VERSION.SDK_INT >= 28) {
                    ImageDecoder.decodeBitmap(ImageDecoder.createSource(resolver, uri)) { decoder, info, _ ->
                        require(info.size.width > 0 && info.size.height > 0 && max(info.size.width, info.size.height) <= 40000)
                        val scale = max(1.0, max(info.size.width, info.size.height) / 1600.0)
                        decoder.setTargetSize(max(1, (info.size.width / scale).toInt()), max(1, (info.size.height / scale).toInt()))
                        decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                    }
                } else {
                    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    resolver.openInputStream(uri).use { BitmapFactory.decodeStream(it, null, bounds) }
                    require(bounds.outWidth > 0 && bounds.outHeight > 0)
                    val options = BitmapFactory.Options().apply { inSampleSize = 1 }
                    while (max(bounds.outWidth, bounds.outHeight) / options.inSampleSize > 1600) options.inSampleSize *= 2
                    val decoded = resolver.openInputStream(uri).use { BitmapFactory.decodeStream(it, null, options) } ?: error("Invalid image")
                    val orientation = resolver.openInputStream(uri).use { stream -> ExifInterface(requireNotNull(stream)).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL) }
                    val matrix = Matrix()
                    when (orientation) {
                        ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
                        ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
                        ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
                        ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
                        ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.setScale(1f, -1f)
                        ExifInterface.ORIENTATION_TRANSPOSE -> { matrix.setScale(-1f, 1f); matrix.postRotate(90f) }
                        ExifInterface.ORIENTATION_TRANSVERSE -> { matrix.setScale(-1f, 1f); matrix.postRotate(270f) }
                    }
                    if (matrix.isIdentity) decoded else Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true).also { decoded.recycle() }
                }
                val bytes = try { ByteArrayOutputStream().use { output ->
                    check(bitmap.compress(Bitmap.CompressFormat.JPEG, 85, output))
                    require(output.size() <= 2 * 1024 * 1024)
                    output.toByteArray()
                } } finally { bitmap.recycle() }
                activity.runOnUiThread { result.success(bytes) }
            } catch (_: Exception) { activity.runOnUiThread { result.error("IMAGE_UNAVAILABLE", "Gambar belum dapat dibaca.", null) } }
        }
        return true
    }
    fun close() { channel.setMethodCallHandler(null); worker.shutdown() }
}
