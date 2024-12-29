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

class ChatListViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    private let firestoreManager = FirestoreManager()

    init() {
        fetchChats()
    }

    // MARK: - Fetch Chats
    func fetchChats() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        firestoreManager.fetchChats(for: userId) { [weak self] result in
            switch result {
            case .success(let chats):
                DispatchQueue.main.async {
                    self?.chats = chats.sorted(by: { ($0.lastMessageDate ?? Date.distantPast) > ($1.lastMessageDate ?? Date.distantPast) })
                }
            case .failure(let error):
                print("Failed to fetch chats: \(error.localizedDescription)")
            }
        }
    }
}
