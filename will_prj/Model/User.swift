//
//  User.swift
//  will_prj
//
//  Created by 邱允聰 on 22/12/2024.
//

import Foundation

struct User: Codable, Identifiable {
    var id: String
    let uid: String
    let email: String
    var displayName: String?    
    var latitude: Double
    var longitude: Double
}
