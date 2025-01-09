//
//  Chat.swift
//  will_prj
//
//  Created by 邱允聰 on 25/12/2024.
//

import Foundation

struct Chat: Codable, Identifiable {
    var id: String? { documentId }
    var documentId: String?
    var users: [User]
    var usersId: [String]{
        return users.map { $0.uid }
    }
    var lastMessage: Message
    
    func toDictionary() throws -> [String: Any] {
        var dictionary = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(self),
            options: .allowFragments
        ) as? [String: Any] ?? [:]
                
        dictionary["usersId"] = usersId
        return dictionary
    }
}
