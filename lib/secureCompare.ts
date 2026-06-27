import crypto from "crypto";

/**
 * Constant-time string comparison.
 *
 * Plain `===` / `!==` on secrets leaks information through how long the
 * comparison takes (it short-circuits on the first differing byte), which can
 * be used to recover a secret byte-by-byte. We hash both inputs to a fixed
 * length first so that neither the contents nor the *length* of the secret
 * leaks, then compare with `crypto.timingSafeEqual`.
 */
export function timingSafeEqualStr(a: string, b: string): boolean {
  const ah = crypto.createHash("sha256").update(String(a), "utf8").digest();
  const bh = crypto.createHash("sha256").update(String(b), "utf8").digest();
  return crypto.timingSafeEqual(ah, bh);
}
