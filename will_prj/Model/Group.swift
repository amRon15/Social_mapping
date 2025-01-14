//
//  Group.swift
//  will_prj  
//
//  Created by 邱允聰 on 12/1/2025.
//

import Foundation
import FirebaseCore
import MapKit

struct GroupModel: Codable, Identifiable {
    var id: String
    var groupName: String
    var users: [User]
    var createUser: String
    var uids: [String]
    var destination: [String: [String:Double]]
    var createdAt: Date? = Date()
    
    func toDictionary() throws -> [String: Any] {
        // Encode the struct to JSON data
        var dictionary = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(self),
            options: .allowFragments
        ) as? [String: Any] ?? [:]
        
        // Replace any necessary values in the dictionary
        dictionary["uids"] = uids // Add uids as a direct array
        dictionary["destination"] = destination // Ensure destination is serialized properly
        
        return dictionary
    }
}
