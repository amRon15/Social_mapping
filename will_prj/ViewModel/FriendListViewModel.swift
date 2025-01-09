//
//  FriendListViewModel.swift
//  will_prj
//
//  Created by 邱允聰 on 9/1/2025.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Firebase
import SwiftUI

class FriendListViewModel: ObservableObject {
    @Published var friendRequests: [User] = []
    @Published var friends: [User] = []
    @Published var currentUser: User?
        
    @Published var selectedFriend: User?
    @Published var showFriendSheet: Bool = false
    
    @Published var user: User?
    @Published var myUser: User?
    var userId: String?
    
    @Published var userImage: Image?
    @Published var chatId: String?
    @Published var isLoading = false
    @Published var navigateToChat = false
    @Published var navigateToProfile = false
    @Published var isFriend = false
    @Published var hasPendingRequest = false
    @Published var hasReceivedRequest = false
    
    private let firestoreManager = FirestoreManager()
    @Environment(\.dismiss) var dismiss
    
    init(){
        if let userId = firestoreManager.user{
            self.userId = userId
            loadCurrentUser(userId)
        }
    }
    
    func loadCurrentUser(_ userId: String) {
        firestoreManager.fetchUserData(userId) { result in
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
    
    func loadFriends() {
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
    
    func loadFriendRequests() {
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
                if let userId = self.userId{
                    self.loadCurrentUser(userId)
                }
            }
        }
    }
    
    func declineFriendRequest(from user: User) {
        guard let currentUser = currentUser else { return }
        firestoreManager.declineFriendRequest(currentUserId: currentUser.uid, requesterId: user.uid) { error in
            if let error = error {
                print("Error declining friend request: \(error.localizedDescription)")
            } else {
                if let userId = self.userId{
                    self.loadCurrentUser(userId)
                }
            }
        }
    }
    
    func checkIfFriend(_ myUser: User, _ user: User) {
        isFriend = myUser.friends.contains(user.uid)
    }
    
    func checkPendingRequest(_ myUser: User, _ user: User) {
        isLoading = true
        FirestoreManager().checkPendingFriendRequest(from: myUser.uid, to: user.uid) { result in
            self.isLoading = false
            switch result {
            case .success(let isPending):
                self.hasPendingRequest = isPending
            case .failure(let error):
                print("Error checking pending request: \(error.localizedDescription)")
                self.hasPendingRequest = false
            }
        }
    }
    
    func checkReceivedRequest(_ myUser: User, _ user: User) {
        hasReceivedRequest = myUser.friendRequests.contains(user.uid)
    }
    
    func acceptFriendRequest(_ myUser: User, _ user: User) {
        isLoading = true
        FirestoreManager().acceptFriendRequest(currentUserId: myUser.uid, requesterId: user.uid) { error in
            self.isLoading = false
            if let error = error {
                print("Error accepting friend request: \(error.localizedDescription)")
            } else {
                self.isFriend = true
                self.hasReceivedRequest = false
                self.dismiss()
            }
        }
    }
    
    func declineFriendRequest(_ myUser: User, _ user: User) {
        isLoading = true
        FirestoreManager().declineFriendRequest(currentUserId: myUser.uid, requesterId: user.uid) { error in
            self.isLoading = false
            if let error = error {
                print("Error declining friend request: \(error.localizedDescription)")
            } else {
                self.hasReceivedRequest = false
                self.dismiss()
            }
        }
    }
    
    func sendFriendRequest(_ myUser: User, _ user: User) {
        isLoading = true
        FirestoreManager().sendFriendRequest(from: myUser.uid, to: user.uid) { error in
            self.isLoading = false
            if let error = error {
                print("Error sending friend request: \(error.localizedDescription)")
            } else {
                self.hasPendingRequest = true
                self.dismiss()
            }
        }
    }
    
    func checkExistingChat(_ myUser: User, _ user: User){
        isLoading = true
        let firestoreManager = FirestoreManager()
        
        firestoreManager.checkExistingChat(between: [myUser, user]) { result in
            switch result {
            case .success(let existingChatId):
                self.chatId = existingChatId
                self.isLoading = false
                self.navigateToChat = true
            case .failure(_):
                self.startChat(myUser, user)
            }
        }
    }
    
    func startChat(_ myUser: User, _ user: User) {
        let firestoreManager = FirestoreManager()
        
        let message = Message(
            id: UUID().uuidString,
            text: "",
            user: user,
            dateCreated: Date()
        )
        
        firestoreManager.sendMessage(
            chatId: nil,
            participants: [myUser, user],
            message: message
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let newChatId):
                    self.chatId = newChatId
                    self.navigateToChat = true
                case .failure(let error):
                    print("Error creating chat: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchImage(_ user: String){
        CloudinaryManager().fetchImage(publicId: user) { image in
            DispatchQueue.main.async {
                if image == nil{
                    self.userImage = Image(systemName: "person.crop.circle.fill")
                }else{
                    self.userImage = image
                }
            }
        }
    }
}
