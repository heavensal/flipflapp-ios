import Foundation
import Security

protocol TokenStoring: Sendable {
    func readToken() async throws -> String?
    func writeToken(_ token: String) async throws
    func deleteToken() async throws
}

actor KeychainTokenStore: TokenStoring {
    private let service: String
    private let account: String

    init(service: String = "fr.flipflapp.ios.session", account: String = "bearer-token") {
        self.service = service
        self.account = account
    }

    func readToken() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw TokenStoreError.keychain(status)
        }
        guard let token = String(data: data, encoding: .utf8), !token.isEmpty else {
            throw TokenStoreError.invalidTokenData
        }
        return token
    }

    func writeToken(_ token: String) throws {
        guard let data = token.data(using: .utf8), !token.isEmpty else {
            throw TokenStoreError.invalidTokenData
        }

        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw TokenStoreError.keychain(updateStatus)
        }

        var insert = baseQuery
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let insertStatus = SecItemAdd(insert as CFDictionary, nil)
        guard insertStatus == errSecSuccess else {
            throw TokenStoreError.keychain(insertStatus)
        }
    }

    func deleteToken() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStoreError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

enum TokenStoreError: LocalizedError, Sendable {
    case keychain(OSStatus)
    case invalidTokenData

    var errorDescription: String? {
        String(localized: "The secure session could not be accessed.")
    }
}
