//
//  ChatViewModel.swift
//  will_prj
//
//  Created by 邱允聰 on 25/12/2024.
//

import Firebase
import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText: String = ""
    private var chatId: String
    private var listenerRegistration: ListenerRegistration?
    private let firestoreManager = FirestoreManager()
    
    private var user: User
    var chatUser: User
    private var participants: [User] = []
    @Published var chatUserImage: Image?
    
    @Published var isLoadingChat: Bool = true
    
    init(user: User, chatUser: User, chatId: String?) {
        self.chatId = chatId ?? ""
        self.user = user
        self.chatUser = chatUser
        fetchUserImage()
        participants = [user, chatUser]
        fetchMessages()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func fetchMessages(){
        DispatchQueue.main.async {
            self.firestoreManager.fetchMessages(chatId: self.chatId, participants: [self.user, self.chatUser]) { result in
                switch result {
                case .success(let (chatId, messages)):
                    if self.chatId == ""{
                        if let chatId = chatId{
                            self.chatId = chatId
                        }
                    }
                    self.isLoadingChat = false
                    self.observeMessages()
                case .failure(let error):
                    print("Failed to fetch messages: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Send Message
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        if chatId == ""{
            let message = Message(id: UUID().uuidString, text: messageText, user: user, dateCreated: Date())
            firestoreManager.sendMessage(chatId: nil, participants: participants, message: message) { result in
                switch result {
                case .success(let chatId):
                    self.chatId = chatId
                    print("Message sent successfully")
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    self.messageText = ""
                case .failure(let error):
                    print("Failed to send message: \(error)")
                }
            }
        } else {
            let message = Message(id: UUID().uuidString, text: messageText, user: user, dateCreated: Date())
            firestoreManager.sendMessage(chatId: chatId, participants: participants, message: message) { result in
                switch result {
                case .success(_):
                    print("Message sent successfully")
                    self.messageText = ""
//                    self.messages.append(message)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                case .failure(let error):
                    print("Failed to send message: \(error)")
                }
            }
        }
        
    }
    
    // MARK: - Observe Messages
    private func observeMessages() {
        listenerRegistration = firestoreManager.observeNewMessages(chatId: chatId){ result in
            switch result {
            case .success(let messages):
                self.messages.append(messages)
                print("Updated messages: \(messages)")
            case .failure(let error):
                print("Failed to observe messages: \(error)")
            }
        }
    }
    
    func fetchUserImage(){
        CloudinaryManager().fetchImage(publicId: chatUser.uid) { image in
            DispatchQueue.main.async {
                self.chatUserImage = image
            }
        }
    }
}
