//
//  FirebaseAuthManager.swift
//  will_prj
//
//  Created by 邱允聰 on 30/12/2024.
//

import Foundation
import FirebaseAuth

class FirebaseAuthManager{
    let auth = Auth.auth()
    
    func isAuth() -> Bool{
        return auth.currentUser != nil
    }
}
