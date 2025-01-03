//
//  Message.swift
//  will_prj
//
//  Created by 邱允聰 on 24/12/2024.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Firebase

struct Message: Codable, Identifiable {
    var id: String    
    let text: String
    var user: User
    var dateCreated: Date? = Date()

    var isMessageOwner: Bool {
        guard let loggedInUserId = Auth.auth().currentUser?.uid else { return false }
        return user.uid == loggedInUserId
    }

    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] ?? [:]
    }
}
