//
//  ChatListViewModel.swift
//  will_prj
//
//  Created by 邱允聰 on 25/12/2024.
//

import Foundation
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class ChatListViewModel: ObservableObject {
    private let firestoreManager = FirestoreManager()
    
    @Published var chats: [Chat] = []
    @Published var usersImage: [String: Image] = [:]
    @Published var userInfo: [String: User?] = [:]
    
    @Published var isLoadingChat: Bool = true
    
    @Published var showFriendList: Bool = false
    @Published var friends: [User] = []
    @Published var friendsImage: [String: Image] = [:]
    @Published var isLoadingFriends: Bool = false
    @Published var selectedUser: User?
    
    @Published var isNavigateToChat: Bool = false
    
    var currentUser: User?
    
    init() {
        fetchChats()
    }
    
    // MARK: - Fetch Chats
    func fetchChats() {
        firestoreManager.fetchChats() { [weak self] result in
            switch result {
            case .success(let chats):
                DispatchQueue.main.async {
                    self?.chats = chats.sorted(by: { ($0.lastMessage.dateCreated ?? Date.distantPast) > ($1.lastMessage.dateCreated ?? Date.distantPast) })
                    self?.getUserInfo()
                    self?.isLoadingChat = false
                }
            case .failure(let error):
                print("Failed to fetch chats: \(error.localizedDescription)")
            }
        }
    }
    
    func getUserInfo(){
        for chat in chats{
            for user in chat.users{
                userInfo[user.uid] = user
            }
        }
        
        if let user = userInfo[firestoreManager.user ?? ""]{
            currentUser = user
        }
        fetchUserImage()
    }
        
    
    func getUser(_ chat: Chat) -> User {
        return chat.users.first(where: { $0.uid != firestoreManager.user })!        
    }
    
    func getUserName(_ chat: Chat) -> String{
        guard let userid = chat.usersId.first(where: { $0 != firestoreManager.user }) else {
            return "Annoymous"
        }
        
        return userInfo[userid]??.displayName ?? "Annoymous"
    }
    
    func getUserImage(_ chat: Chat) -> Image {
        guard let userid = chat.usersId.first(where: { $0 != firestoreManager.user }) else {
            return Image(systemName: "person.circle")
        }
        
        return usersImage[userid] ?? Image(systemName: "person.circle")
    }
    
    func toDate(_ time: Date?) -> String{
        var date: String = ""
        if let time = time{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            let dateString = dateFormatter.string(from: time)
            date = dateString
        }
        return date
    }
    
    func messagePrefix(for chat: Chat) -> String {
        let isCurrentUserMessageOwner = chat.lastMessage.user.uid == firestoreManager.user
        return isCurrentUserMessageOwner ? "You: " : "\(chat.lastMessage.user.displayName ?? "Annoymous"): "
    }
    
    func fetchUserImage(){
        for userid in userInfo.keys{
            CloudinaryManager().fetchImage(publicId: userid) { image in
                DispatchQueue.main.async {
                    self.usersImage[userid] = image
                }
            }
        }
    }
    
    func loadFriends() {
        guard let currentUser = currentUser else { return }
        isLoadingFriends = true
        firestoreManager.fetchUserInfo(uids: currentUser.friends) { result in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self.friends = users
                    self.isLoadingFriends = false
                    self.fetchFriendsImage()
                }
            case .failure(let error):
                print("Error loading friends: \(error.localizedDescription)")
                self.isLoadingFriends = false
            }
        }
    }
    
    func fetchFriendsImage(){
        for friend in friends {
            CloudinaryManager().fetchImage(publicId: friend.uid) { image in
                DispatchQueue.main.async{
                    self.friendsImage[friend.uid] = image
                }
            }
        }
    }
    
    func getFriendsImage(_ user: User) -> Image{
        return friendsImage[user.uid] ?? Image(systemName: "person.crop.circle.fill")
    }
    
    func navigateToChat(_ user: User){
        isNavigateToChat.toggle()
        showFriendList.toggle()
        selectedUser = user
    }
}
