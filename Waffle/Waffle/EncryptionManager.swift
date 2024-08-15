import Foundation
import CryptoKit

class EncryptionManager {
    // Use a constant string to derive the key, so it's consistent across app launches
    private static let keyString = "thisappisnotinproductionyet"  // Replace with a secure, secret string
    private static let key: SymmetricKey = {
        let keyData = Data(keyString.utf8)
        return SymmetricKey(data: SHA256.hash(data: keyData))
    }()
    
    static func encrypt(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined?.base64EncodedString()
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    static func decrypt(_ string: String) -> String? {
        guard let data = Data(base64Encoded: string) else { return nil }
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            // Instead of printing the error, return nil
            return nil
        }
    }
    
    static func isEncrypted(_ string: String) -> Bool {
        guard let _ = Data(base64Encoded: string) else { return false }
        return decrypt(string) != nil
    }
}
