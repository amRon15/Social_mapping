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
    @Published var userId: String?
    @Published var isMyUser: Bool = true
    
    let columns = [GridItem(),GridItem()]
    
    init(_ user: String){
        self.userId = userId
        getUserData(user)
        isMyUser = FirestoreManager().user == userId
    }
    
    func getUserData(_ userId: String){
        FirestoreManager().fetchUserData(userId) { result in
            switch result {
            case .success(let success):
                self.user = success
            case .failure(let failure):
                print("Profile fetch user data failed: \(failure.localizedDescription)")
            }
        }
        
        CloudinaryManager().fetchImage(publicId: userId) { result in
            DispatchQueue.main.async{
                if result == nil{
                    self.userImage = Image(systemName: "person.crop.circle.fill")
                } else{
                    self.userImage = result
                }
            }
        }
    }
    
    func getUserPost(){
        
    }
    
    
}
