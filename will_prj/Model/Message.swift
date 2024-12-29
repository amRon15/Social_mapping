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
    var id: String? { documentId }
    var documentId: String?
    let text: String
    let uid: String
    var dateCreated: Date? = Date()
    let displayName: String
    var profilePhotoURL: String = ""

    var isMessageOwner: Bool {
        guard let loggedInUserId = Auth.auth().currentUser?.uid else { return false }
        return uid == loggedInUserId
    }

    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] ?? [:]
    }
}
