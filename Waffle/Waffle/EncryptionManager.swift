import Foundation
import CryptoKit

class EncryptionManager {
    private static let keyString = "notInProduction"
    private static let key: SymmetricKey = {
        let keyData = Data(keyString.utf8)
        return SymmetricKey(data: SHA256.hash(data: keyData))
    }()
    
    static func encrypt(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else {
            print("Encryption failed: Unable to convert string to data")
            return nil
        }
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            let encrypted = sealedBox.combined?.base64EncodedString()
            print("Encryption successful. Original length: \(string.count), Encrypted length: \(encrypted?.count ?? 0)")
            return encrypted
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    static func isEncrypted(_ string: String) -> Bool {
        let base64Regex = "^[A-Za-z0-9+/\\-_]*={0,2}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", base64Regex)
        return predicate.evaluate(with: string)
    }

    static func decrypt(_ string: String) -> String? {
        var base64 = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        guard let data = Data(base64Encoded: base64) else {
            print("Decryption failed: Invalid base64 encoding")
            return nil
        }
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                print("Decryption failed: Unable to convert data to string")
                return nil
            }
            print("Decryption successful. Encrypted length: \(string.count), Decrypted length: \(decryptedString.count)")
            return decryptedString
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
}
