//
//  KeychainManager.swift
//  will_prj
//
//  Created by 邱允聰 on 27/12/2024.
//

import Foundation
import Security

class KeychainManager{
    
    func storePassword(account: String, password: String){
        let passwordData = password.data(using: .utf8)
        UserDefaults().set(account, forKey: "UserEmail")
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: account,
                                    kSecValueData as String: passwordData,
                                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked]
        
        let status = SecItemAdd(query as CFDictionary, nil)
    }
    
    func retreivePassword(_ email: String) -> String?{
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
}
