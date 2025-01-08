//
//  FriendList.swift
//  will_prj
//
//  Created by Fung Matthew on 8/1/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Firebase

class FriendListViewModel: ObservableObject {
    @Published var friendRequests: [User] = []
    @Published var friends: [User] = []
    @Published var currentUser: User?
    private let firestoreManager = FirestoreManager()
    
    init() {
        loadCurrentUser()
    }
    
    private func loadCurrentUser() {
        firestoreManager.fetchUserData { result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.loadFriends()
                    self.loadFriendRequests()
                }
            case .failure(let error):
                print("Error loading current user: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadFriends() {
        guard let currentUser = currentUser else { return }
        firestoreManager.fetchUserInfo(uids: currentUser.friends) { result in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self.friends = users
                }
            case .failure(let error):
                print("Error loading friends: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadFriendRequests() {
        guard let currentUser = currentUser else { return }
        firestoreManager.fetchUserInfo(uids: currentUser.friendRequests) { result in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self.friendRequests = users
                }
            case .failure(let error):
                print("Error loading friend requests: \(error.localizedDescription)")
            }
        }
    }
    
    func acceptFriendRequest(from user: User) {
        guard let currentUser = currentUser else { return }
        firestoreManager.acceptFriendRequest(currentUserId: currentUser.uid, requesterId: user.uid) { error in
            if let error = error {
                print("Error accepting friend request: \(error.localizedDescription)")
            } else {
                self.loadCurrentUser()
            }
        }
    }
    
    func declineFriendRequest(from user: User) {
        guard let currentUser = currentUser else { return }
        firestoreManager.declineFriendRequest(currentUserId: currentUser.uid, requesterId: user.uid) { error in
            if let error = error {
                print("Error declining friend request: \(error.localizedDescription)")
            } else {
                self.loadCurrentUser()
            }
        }
    }
}
