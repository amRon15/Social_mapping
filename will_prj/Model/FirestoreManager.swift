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
    
    func sendMessage(to chatId: String, message: Message, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let chatRef = db.collection("chats").document(chatId)
            let newMessageRef = chatRef.collection("messages").document()
            var messageData = try message.toDictionary()
            messageData["dateCreated"] = FieldValue.serverTimestamp()
            
            newMessageRef.setData(messageData) { error in
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
    
    func observeMessages(in chatId: String, completion: @escaping (Result<[Message], Error>) -> Void) -> ListenerRegistration {
        let chatRef = db.collection("chats").document(chatId)
        return chatRef.collection("messages")
            .order(by: "dateCreated")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let messages: [Message] = documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }
                completion(.success(messages))
            }
    }
    
    func fetchChats(for userId: String, completion: @escaping (Result<[Chat], Error>) -> Void) {
        db.collection("chats")
            .whereField("participantIds", arrayContains: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let chats: [Chat] = documents.compactMap { doc in
                    try? doc.data(as: Chat.self)
                }
                completion(.success(chats))
            }
    }
}
