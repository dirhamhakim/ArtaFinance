package id.arta.arta

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.biometrics.BiometricPrompt
import android.hardware.biometrics.BiometricManager
import android.hardware.fingerprint.FingerprintManager
import android.os.Build
import android.os.CancellationSignal
import android.os.SystemClock
import android.provider.Settings
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.security.KeyStore
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import kotlin.math.min

/** Device-only PIN verifier; no PIN or verifier crosses back to Flutter. */
class AppSecurityBridge(private val activity: FlutterActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "id.arta.arta/security")
    private val worker = Executors.newSingleThreadExecutor()
    private val prefs = activity.getSharedPreferences("arta_security", Context.MODE_PRIVATE)
    @Volatile private var authorized = false
    @Volatile private var generation = 0
    private var biometric: CancellationSignal? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "lock" -> {
                    invalidate()
                    result.success(null)
                }
                "biometric" -> authenticate(result)
                else -> worker.execute {
                    try {
                        val state = readState()
                        val reply: Any = when (call.method) {
                            "getPriceKey" -> {
                                check(!state.optBoolean("enabled") || authorized)
                                val saved = prefs.getString("coingecko", null)
                                if (saved == null) "" else decryptText(saved)
                            }
                            "setPriceKey" -> {
                                check(!state.optBoolean("enabled") || authorized)
                                val value = call.argument<String>("value") ?: ""
                                require(value.length <= 256 && !value.contains('\n') && !value.contains('\r'))
                                check(prefs.edit().putString("coingecko", encryptText(value)).commit())
                                true
                            }
                            "status" -> status(state)
                            "configure" -> {
                                val configurationGeneration = generation
                                check(!state.optBoolean("enabled") || authorized) { "Authentication required" }
                                val pin = call.argument<String>("pin") ?: ""
                                require(PinPolicy.valid(pin)) { "PIN must have six digits" }
                                val salt = ByteArray(16).also { SecureRandom().nextBytes(it) }
                                val kdf = if (Build.VERSION.SDK_INT >= 26) "PBKDF2WithHmacSHA256" else "PBKDF2WithHmacSHA1"
                                val next = JSONObject().put("enabled", true)
                                    .put("biometric", call.argument<Boolean>("biometric") == true && biometricAvailable())
                                    .put("salt", encode(salt)).put("hash", encode(PinPolicy.derive(pin, salt, kdf)))
                                    .put("kdf", kdf).put("failures", 0).put("until", 0L)
                                writeState(next)
                                authorize(configurationGeneration)
                                status(next)
                            }
                            "disable" -> {
                                check(authorized) { "Authentication required" }
                                val next = JSONObject().put("enabled", false)
                                writeState(next)
                                status(next)
                            }
                            "verifyPin" -> {
                                check(state.optBoolean("enabled")) { "Lock is not enabled" }
                                val attemptGeneration = generation
                                val cooldown = remaining(state)
                                if (cooldown > 0) mapOf("ok" to false, "retry" to cooldown)
                                else {
                                    val pin = call.argument<String>("pin") ?: ""
                                    require(PinPolicy.valid(pin))
                                    val valid = MessageDigest.isEqual(
                                        PinPolicy.derive(pin, decode(state.getString("salt")), state.getString("kdf")),
                                        decode(state.getString("hash"))
                                    )
                                    if (valid) {
                                state.put("failures", 0).put("until", 0L).put("untilElapsed", 0L)
                                    } else {
                                        val failures = state.optInt("failures") + 1
                                        val wait = PinPolicy.delaySeconds(failures)
                                        state.put("failures", failures).put("until", System.currentTimeMillis() + wait * 1000L)
                                            .put("untilElapsed", SystemClock.elapsedRealtime() + wait * 1000L).put("boot", bootCount())
                                    }
                                    writeState(state)
                                    val accepted = valid && authorize(attemptGeneration)
                                    mapOf("ok" to accepted, "retry" to remaining(state))
                                }
                            }
                            else -> throw IllegalArgumentException("Unknown security method")
                        }
                        activity.runOnUiThread { result.success(reply) }
                    } catch (error: Exception) {
                        // Do not reset unreadable credentials: fail closed.
                        activity.runOnUiThread { result.error("SECURITY_UNAVAILABLE", "Keamanan lokal belum dapat diproses.", null) }
                    }
                }
            }
        }
    }

    private fun status(state: JSONObject): Map<String, Any> {
        val enabled = state.optBoolean("enabled")
        activity.runOnUiThread {
            if (enabled) activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            else activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        return mapOf("enabled" to enabled, "biometric" to state.optBoolean("biometric"), "available" to biometricAvailable(), "retry" to remaining(state))
    }

    private fun bootCount() = Settings.Global.getInt(activity.contentResolver, Settings.Global.BOOT_COUNT, -1)
    private fun remaining(state: JSONObject): Int {
        val remaining = if (state.optInt("boot", -2) == bootCount()) state.optLong("untilElapsed") - SystemClock.elapsedRealtime()
            else state.optLong("until") - System.currentTimeMillis()
        return ((remaining + 999).coerceAtLeast(0) / 1000).coerceAtMost(300).toInt()
    }

    @Synchronized private fun authorize(expectedGeneration: Int): Boolean {
        if (expectedGeneration != generation) return false
        authorized = true
        return true
    }
    @Synchronized fun invalidate() { generation++; authorized = false; biometric?.cancel() }

    @SuppressLint("MissingPermission")
    @Suppress("DEPRECATION")
    private fun biometricAvailable(): Boolean = Build.VERSION.SDK_INT >= 28 &&
        activity.packageManager.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT) &&
        activity.getSystemService(FingerprintManager::class.java)?.hasEnrolledFingerprints() == true

    private fun authenticate(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 28 || !biometricAvailable()) { result.success(false); return }
        val current = generation
        val completed = AtomicBoolean(false)
        fun finish(ok: Boolean) {
            if (completed.compareAndSet(false, true)) {
                biometric = null
                activity.runOnUiThread { result.success(ok) }
            }
        }
        try {
            val state = readState()
            if (!state.optBoolean("enabled") || !state.optBoolean("biometric")) { finish(false); return }
            val builder = BiometricPrompt.Builder(activity).setTitle("Buka Arta")
                .setSubtitle("Gunakan sidik jari yang terdaftar di HP")
                .setNegativeButton("Gunakan PIN Arta", activity.mainExecutor) { _, _ -> finish(false) }
            if (Build.VERSION.SDK_INT >= 30) builder.setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            val prompt = builder.build()
            val signal = CancellationSignal()
            biometric = signal
            prompt.authenticate(signal, activity.mainExecutor, object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    worker.execute {
                        try {
                            val accepted = current == generation
                            if (accepted) {
                                val next = readState().put("failures", 0).put("until", 0L).put("untilElapsed", 0L)
                                writeState(next)
                            }
                            finish(accepted && authorize(current))
                        } catch (_: Exception) { finish(false) }
                    }
                }
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) { finish(false) }
            })
        } catch (_: Exception) { finish(false) }
    }

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val alias = "arta.device.security.v1"
        val stored = store.getKey(alias, null)
        if (stored != null) return stored as SecretKey
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
        }.generateKey()
    }
    private fun readState(): JSONObject {
        val encrypted = prefs.getString("state", null) ?: return JSONObject().put("enabled", false)
        return JSONObject(decryptText(encrypted))
    }
    private fun decryptText(encrypted: String): String {
        val parts = encrypted.split(":")
        require(parts.size == 2)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, decode(parts[0])))
        return String(cipher.doFinal(decode(parts[1])), Charsets.UTF_8)
    }
    private fun writeState(state: JSONObject) {
        check(prefs.edit().putString("state", encryptText(state.toString())).commit())
    }
    private fun encryptText(value: String): String {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val encrypted = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        return "${encode(cipher.iv)}:${encode(encrypted)}"
    }
    private fun encode(bytes: ByteArray) = Base64.encodeToString(bytes, Base64.NO_WRAP)
    private fun decode(value: String) = Base64.decode(value, Base64.NO_WRAP)

    fun close() { generation++; biometric?.cancel(); channel.setMethodCallHandler(null); worker.shutdown() }
}
