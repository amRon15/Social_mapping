//
//  ChatViewModel.swift
//  will_prj
//
//  Created by 邱允聰 on 25/12/2024.
//

import Firebase
import Foundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseFirestore

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText: String = ""
    private var chatId: String
    private var listenerRegistration: ListenerRegistration?
    private let firestoreManager = FirestoreManager()

    init(chatId: String) {
        self.chatId = chatId
        observeMessages()
    }

    deinit {
        listenerRegistration?.remove()
    }

    // MARK: - Send Message
    func sendMessage(displayName: String, profilePhotoURL: String) {
        guard !messageText.isEmpty else { return }
        
        let message = Message(
            documentId: nil,
            text: messageText,
            uid: Auth.auth().currentUser?.uid ?? "",
            dateCreated: nil,
            displayName: displayName,
            profilePhotoURL: profilePhotoURL
        )

        firestoreManager.sendMessage(to: chatId, message: message) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.messageText = ""
                }
            case .failure(let error):
                print("Failed to send message: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Observe Messages
    private func observeMessages() {
        listenerRegistration = firestoreManager.observeMessages(in: chatId) { [weak self] result in
            switch result {
            case .success(let messages):
                DispatchQueue.main.async {
                    self?.messages = messages
                }
            case .failure(let error):
                print("Failed to fetch messages: \(error.localizedDescription)")
            }
        }
    }
}
