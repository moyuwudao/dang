"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CryptoUtil = void 0;
const crypto = require("crypto");
const ALGORITHM = 'aes-256-cbc';
const IV_LENGTH = 16;
class CryptoUtil {
    static getKey() {
        const secret = process.env.CRYPTO_SECRET || 'changji-default-secret-key-change-in-production';
        return crypto.createHash('sha256').update(secret).digest();
    }
    static encrypt(text) {
        const iv = crypto.randomBytes(IV_LENGTH);
        const key = this.getKey();
        const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
        let encrypted = cipher.update(text, 'utf8', 'hex');
        encrypted += cipher.final('hex');
        return iv.toString('hex') + ':' + encrypted;
    }
    static decrypt(encryptedText) {
        const parts = encryptedText.split(':');
        const iv = Buffer.from(parts.shift(), 'hex');
        const encrypted = parts.join(':');
        const key = this.getKey();
        const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
        let decrypted = decipher.update(encrypted, 'hex', 'utf8');
        decrypted += decipher.final('utf8');
        return decrypted;
    }
}
exports.CryptoUtil = CryptoUtil;
//# sourceMappingURL=crypto.util.js.map