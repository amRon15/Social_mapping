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
    let participantIds: [String]
    var lastMessage: String = ""
    var lastMessageDate: Date? = nil

    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] ?? [:]
    }
}
