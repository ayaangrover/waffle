import Foundation
import CryptoKit

class EncryptionManager {
    private static let salt = "WaffleSaltValue".data(using: .utf8)!
    private static let passwordKey = SymmetricKey(data: SHA256.hash(data: "WaffleSecretPassword".data(using: .utf8)!))
    
    static func encrypt(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else {
            print("Encryption failed: Unable to convert string to data")
            return nil
        }
        do {
            let encrypted = try ChaChaPoly.seal(data, using: passwordKey, nonce: try ChaChaPoly.Nonce(data: salt))
            let encryptedString = encrypted.combined.base64EncodedString()
            print("Encryption successful. Original length: \(string.count), Encrypted length: \(encryptedString.count)")
            return encryptedString
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    static func decrypt(_ encryptedString: String) -> String? {
        guard let data = Data(base64Encoded: encryptedString) else {
            print("Decryption failed: Invalid base64 encoding")
            return nil
        }
        do {
            let sealedBox = try ChaChaPoly.SealedBox(combined: data)
            let decryptedData = try ChaChaPoly.open(sealedBox, using: passwordKey, authenticating: salt)
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                print("Decryption failed: Unable to convert data to string")
                return nil
            }
            print("Decryption successful. Encrypted length: \(encryptedString.count), Decrypted length: \(decryptedString.count)")
            return decryptedString
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
    
    static func isEncrypted(_ string: String) -> Bool {
        let base64Regex = "^[A-Za-z0-9+/\\-_]*={0,2}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", base64Regex)
        return predicate.evaluate(with: string)
    }
}
