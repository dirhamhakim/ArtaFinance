package id.arta.arta

import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec
import kotlin.math.min

internal object PinPolicy {
    const val iterations = 600000
    fun valid(pin: String) = pin.matches(Regex("[0-9]{6}"))
    fun delaySeconds(failures: Int): Int = if (failures < 5) 0 else min(300, 30 * (1 shl min(4, failures - 5)))
    fun derive(pin: String, salt: ByteArray, algorithm: String): ByteArray {
        require(valid(pin) && salt.size == 16)
        val spec = PBEKeySpec(pin.toCharArray(), salt, iterations, 256)
        return try { SecretKeyFactory.getInstance(algorithm).generateSecret(spec).encoded } finally { spec.clearPassword() }
    }
}
