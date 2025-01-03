//
//  FirestoreManager.swift
//  will_prj
//
//  Created by 邱允聰 on 26/12/2024.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import MapKit

class FirestoreManager {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    let user = Auth.auth().getUserID()
    
    func fetchUserInfo(uids: [String], completion: @escaping (Result<[User], Error>) -> Void) {
        let usersRef = db.collection("users")
        
        usersRef.whereField("uid", in: uids).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.failure(NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No documents found."])))
                return
            }
            
            let users = documents.compactMap { doc in
                try? doc.data(as: User.self)
            }
            completion(.success(users))
        }
    }


    
    func fetchUserData(completion: @escaping (Result<User, Error>) -> Void) {
        if let userId = user{
            let userRef = db.collection("users").document(userId)
            userRef.getDocument { document, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = document, document.exists,
                      let data = try? document.data(as: User.self) else {
                    completion(.failure(NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user data."])))
                    return
                }
                
                completion(.success(data))
            }
        } else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated."])))
            return
        }
    }
    
    func fetchNearbyUsers(currentLocation: CLLocation, completion: @escaping (Result<[User], Error>) -> Void) {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            var nearbyUsers: [User] = []
            
            for document in documents {
                guard let data = document.data() as? [String: Any],
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let email = data["email"] as? String,
                      let uid = data["uid"] as? String,
                      let id = data["id"] as? String,
                      let displayName = data["displayName"] as? String else {
                    continue
                }
                
                let userLocation = CLLocation(latitude: latitude, longitude: longitude)
                let distance = currentLocation.distance(from: userLocation)
                
                if distance <= 500 {
                    let user = User(id: id, uid: uid, email: email, displayName: displayName, latitude: latitude, longitude: longitude)
                    nearbyUsers.append(user)
                }
            }
            
            completion(.success(nearbyUsers))
        }
    }
    
    func saveUserData(user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRef = db.collection("users").document(user.uid)
        print(user.uid)
        do {
            try userRef.setData(from: user) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func updateUserLocation(location: CLLocation, completion: @escaping (Result<Void, Error>) -> Void) {
        if let user = user{
            Task{
                do{
                    db.collection("users").document(user).updateData([
                        "latitude": location.coordinate.latitude,
                        "longitude": location.coordinate.longitude
                    ])
                    completion(.success(()))
                } catch{
                    completion(.failure(error))
                }
            }
        }
    }
    // MARK: - Get User Location
    func getUserLocation(userId: String, completion: @escaping (Result<CLLocation, Error>) -> Void) {
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data(),
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double else {
                completion(.failure(NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location data not found"])))
                return
            }
            
            let location = CLLocation(latitude: latitude, longitude: longitude)
            completion(.success(location))
        }
    }
    
    func sendMessage(chatId: String?, participants: [User], message: Message, completion: @escaping (Result<String, Error>) -> Void) {
        let chatRef: DocumentReference
        let isNewChat = (chatId == nil)
        
        if let chatId = chatId {
            chatRef = db.collection("chats").document(chatId)
        } else {
            chatRef = db.collection("chats").document() // Create a new chat
        }
        
        do {
            let chatData: [String: Any]
            if isNewChat {
                // Creating a new chat
                let chat = Chat(documentId: chatRef.documentID, users: participants, lastMessage: message)                
                chatData = try chat.toDictionary()
            } else {
                // Updating an existing chat
                chatData = ["lastMessage": try message.toDictionary()]
            }
            
            chatRef.setData(chatData, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // Save the message in the "messages" subcollection
                    let messageRef = chatRef.collection("messages").document()
                    let messageData = try? message.toDictionary()
                    
                    messageRef.setData(messageData ?? [:]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(chatRef.documentID)) // Return the chatId
                        }
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    
    func fetchMessages(chatId: String, participants: [User], completion: @escaping (Result<(String?, [Message]), Error>) -> Void) {
        if chatId != "" {
            // Fetch all messages for the given chatId
            let messagesRef = db.collection("chats").document(chatId).collection("messages")
            messagesRef
                .order(by: "dateCreated", descending: false)
                .getDocuments { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let documents = snapshot?.documents {
                        let messages: [Message] = documents.compactMap { doc in
                            var message = try? JSONDecoder().decode(Message.self, from: JSONSerialization.data(withJSONObject: doc.data()))
                            message?.id = doc.documentID
                            return message
                        }
                        completion(.success((chatId, messages)))
                    }
                }
        } else {
            // Find chat by participants
            let participantIds = participants.map { $0.uid }
            let chatsRef = db.collection("chats")
            
            chatsRef
                .whereField("usersId", isEqualTo: participantIds)
                .getDocuments { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let documents = snapshot?.documents, let chatDocument = documents.first {
                        let chatId = chatDocument.documentID
                        let messagesRef = chatsRef.document(chatId).collection("messages")
                        
                        messagesRef
                            .order(by: "dateCreated", descending: false)
                            .getDocuments { snapshot, error in
                                if let error = error {
                                    completion(.failure(error))
                                } else if let documents = snapshot?.documents {
                                    let messages: [Message] = documents.compactMap { doc in
                                        var message = try? JSONDecoder().decode(Message.self, from: JSONSerialization.data(withJSONObject: doc.data()))
                                        message?.id = doc.documentID
                                        return message
                                    }
                                    completion(.success((chatId, messages)))
                                }
                            }
                    } else {
                        completion(.failure(NSError(domain: "ChatError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chat not found"])))
                    }
                }
        }
    }
    
    
    func observeNewMessages(chatId: String, onNewMessage: @escaping (Result<Message, Error>) -> Void) -> ListenerRegistration? {
        let db = Firestore.firestore()
        let messagesRef = db.collection("chats").document(chatId).collection("messages")
        
        return messagesRef
            .order(by: "dateCreated", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    onNewMessage(.failure(error))
                } else if let documents = snapshot?.documentChanges {
                    for change in documents {
                        if change.type == .added {
                            var message = try? JSONDecoder().decode(Message.self, from: JSONSerialization.data(withJSONObject: change.document.data()))
                            message?.id = change.document.documentID
                            if let newMessage = message {
                                onNewMessage(.success(newMessage))
                            }
                        }
                    }
                }
            }
    }
    
    func fetchChats(completion: @escaping (Result<[Chat], Error>) -> Void) {
        guard let currentUserId = user else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        db.collection("chats")
            .whereField("usersId", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else if let documents = snapshot?.documents {
                    let chats: [Chat] = documents.compactMap { doc in
                        var chat = try? JSONDecoder().decode(Chat.self, from: JSONSerialization.data(withJSONObject: doc.data()))
                        chat?.documentId = doc.documentID
                        return chat
                    }
                    completion(.success(chats))
                }
            }
    }
    
}
