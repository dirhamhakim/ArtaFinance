package id.arta.arta

import java.security.MessageDigest

fun main() {
    check(PinPolicy.valid("012345"))
    check(!PinPolicy.valid("12345") && !PinPolicy.valid("1234567") && !PinPolicy.valid("12a456"))
    check((0..4).all { PinPolicy.delaySeconds(it) == 0 })
    check((5..10).map { PinPolicy.delaySeconds(it) } == listOf(30, 60, 120, 240, 300, 300))
    val salt = ByteArray(16) { it.toByte() }
    for (algorithm in listOf("PBKDF2WithHmacSHA256", "PBKDF2WithHmacSHA1")) {
        val hash = PinPolicy.derive("012345", salt, algorithm)
        check(hash.size == 32)
        check(MessageDigest.isEqual(hash, PinPolicy.derive("012345", salt, algorithm)))
        check(!MessageDigest.isEqual(hash, PinPolicy.derive("543210", salt, algorithm)))
        check(!MessageDigest.isEqual(hash, PinPolicy.derive("012345", ByteArray(16) { (it + 1).toByte() }, algorithm)))
    }
    println("PIN policy: validation, progressive cooldown, SHA256/SHA1 salt and verifier checks passed.")
}
