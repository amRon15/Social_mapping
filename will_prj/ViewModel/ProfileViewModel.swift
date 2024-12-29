//
//  ProfileViewModel.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import Foundation
import SwiftUI

class ProfileViewModel: ObservableObject{
    @Published var isLogout: Bool = false
    @Published var user: User?
    @Published var userImage: Image?
    
    let columns = [GridItem(),GridItem()]
    
    init(){
        getUserData()
    }
    
    func getUserData(){
        FirestoreManager().fetchUserData { result in
            switch result {
            case .success(let success):
                self.user = success
            case .failure(let failure):
                print("Profile fetch user data failed: \(failure.localizedDescription)")
            }
        }
        
        if let userId = FirestoreManager().user{
            CloudinaryManager().fetchImage(publicId: userId) { result in
                DispatchQueue.main.async{
                    self.userImage = result
                }
            }
        }
    }
    
    func getUserPost(){
        
    }
    
    
}
