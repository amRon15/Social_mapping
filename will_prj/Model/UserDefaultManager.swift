//
//  UserDefaultManager.swift
//  will_prj
//
//  Created by 邱允聰 on 23/12/2024.
//

import Foundation

class UserDefaultManager{
    static var userId: String? {
        get{
            UserDefaults.standard.string(forKey: "userId")
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "userId")
        }
    }
}
