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
import MapKit

class FirestoreManager {
    private let db = Firestore.firestore()
    let user = Auth.auth().getUserID()
    
    func fetchUserInfo(uids: [String], completion: @escaping (Result<[User], Error>) -> Void) {
        guard !uids.isEmpty else {
            completion(.success([]))
            return
        }
        
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
    
    
    func fetchUserData(_ userId: String?, completion: @escaping (Result<User, Error>) -> Void) {
        if let userId = userId{
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
                      let displayName = data["displayName"] as? String,
                      let friendRequests = data["friendRequests"] as? [String],
                      let friends = data["friends"] as? [String] else {
                    continue
                }
                
                let userLocation = CLLocation(latitude: latitude, longitude: longitude)
                let distance = currentLocation.distance(from: userLocation)
                
                if distance <= 500 {
                    let user = User(id: id,
                                    uid: uid,
                                    email: email,
                                    displayName: displayName,
                                    latitude: latitude,
                                    longitude: longitude,
                                    friendRequests: friendRequests,
                                    friends: friends)
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
            chatRef = db.collection("chats").document()
        }
        
        do {
            let chatData: [String: Any]
            if isNewChat {
                let chat = Chat(documentId: chatRef.documentID, users: participants, lastMessage: message)
                chatData = try chat.toDictionary()
            } else {
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
                            completion(.success(chatRef.documentID))
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
    
    func checkExistingChat(between users: [User], completion: @escaping (Result<String?, Error>) -> Void) {
        let userIds = users.map { $0.uid }.sorted()
        let chatsRef = db.collection("chats")
        
        chatsRef
            .whereField("usersId", isEqualTo: userIds)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let document = snapshot?.documents.first {
                    completion(.success(document.documentID))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No existing chat found"])))
                }
            }
    }
    
    func fetchUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        let usersRef = db.collection("users")
        
        usersRef.document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data(),
                  let user = try? Firestore.Decoder().decode(User.self, from: data) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode user"])))
                return
            }
            
            completion(.success(user))
        }
    }
    
    func sendFriendRequest(from currentUserId: String, to userId: String, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { (document, error) in
            if let error = error {
                completion(error)
                return
            }
            
            guard let document = document, document.exists,
                  let friendRequests = document.data()?["friendRequests"] as? [String] else {
                completion(NSError(domain: "FirestoreError", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "User document not found"]))
                return
            }
            
            if friendRequests.contains(currentUserId) {
                completion(NSError(domain: "FirestoreError", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Friend request already sent"]))
                return
            }
            
            userRef.updateData([
                "friendRequests": FieldValue.arrayUnion([currentUserId])
            ]) { error in
                if let error = error {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
    }
    func acceptFriendRequest(currentUserId: String, requesterId: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        let currentUserRef = db.collection("users").document(currentUserId)
        let requesterRef = db.collection("users").document(requesterId)
        
        batch.updateData([
            "friendRequests": FieldValue.arrayRemove([requesterId]),
            "friends": FieldValue.arrayUnion([requesterId])
        ], forDocument: currentUserRef)
                
        batch.updateData([
            "friends": FieldValue.arrayUnion([currentUserId])
        ], forDocument: requesterRef)
        
        batch.commit(completion: completion)
    }
    
    func declineFriendRequest(currentUserId: String, requesterId: String, completion: @escaping (Error?) -> Void) {
        let currentUserRef = db.collection("users").document(currentUserId)
        
        currentUserRef.updateData([
            "friendRequests": FieldValue.arrayRemove([requesterId])
        ], completion: completion)
    }
    
    func checkPendingFriendRequest(from currentUserId: String, to userId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document,
                  let friendRequests = document.data()?["friendRequests"] as? [String] else {
                completion(.success(false))
                return
            }
            
            completion(.success(friendRequests.contains(currentUserId)))
        }
    }
    
    func createGroup(name: String, selectedFriends: [User], destination: CLLocationCoordinate2D, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = user else {return}
        do {
            let uids = selectedFriends.map { $0.uid }
                        
            let grpRef: DocumentReference = db.collection("groups").document()
            
            let grpData: [String: Any]
            let group = GroupModel(id: grpRef.documentID, groupName: name, users: selectedFriends, createUser: uid ,uids: uids, destination:
                                ["destination": ["latitude": destination.latitude,"longitude":destination.longitude]])
            
            grpData = try group.toDictionary()
            
            grpRef.setData(grpData, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success("Group created successfully"))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func observeGroups(completion: @escaping (Result<[GroupModel], Error>) -> Void) {
            if let user = user{
                let groupsRef = db.collection("groups")
                
                groupsRef.addSnapshotListener { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion(.success([]))
                        return
                    }
                    
                    var groups: [GroupModel] = []
                    
                    for document in documents {
                        do {
                            let groupData = document.data()
                            if let uids = groupData["uids"] as? [String], uids.contains(user) {
                                let groupJSON = try JSONSerialization.data(withJSONObject: groupData, options: [])
                                let group = try JSONDecoder().decode(GroupModel.self, from: groupJSON)
                                groups.append(group)
                            }
                        } catch {
                            print("Failed to decode group: \(error.localizedDescription)")
                        }
                    }
                    completion(.success(groups))
                }
            }
        }

    
    func observeGroup(_ id: String, completion: @escaping (Result<GroupModel, Error>) -> Void) -> ListenerRegistration {
        let documentRef = db.collection("groups").document(id)
        
        let listener = documentRef.addSnapshotListener { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documentSnapshot = documentSnapshot, documentSnapshot.exists else {
                completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found"])))
                return
            }
            
            do {
                let groupData = documentSnapshot.data() ?? [:]
                let groupJSON = try JSONSerialization.data(withJSONObject: groupData, options: [])
                let group = try JSONDecoder().decode(GroupModel.self, from: groupJSON)
                completion(.success(group))
            } catch {
                print("Failed to decode group: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        return listener
    }

    func stopObservingGroup(listener: ListenerRegistration?) {
        listener?.remove()
    }
    
    func deleteGroup(_ id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let documentRef = db.collection("groups").document(id)
        
        documentRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateCurrentUserLocation(user: User) {
        db.collection("groups").whereField("uids", arrayContains: user.uid).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching groups: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No groups found for user.")
                return
            }
            
            for document in documents {
                let groupRef = document.reference
                
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    let groupSnapshot: DocumentSnapshot
                    do {
                        groupSnapshot = try transaction.getDocument(groupRef)
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                                        
                    guard var users = groupSnapshot.data()?["users"] as? [[String: Any]] else {
                        print("Failed to fetch users array.")
                        return nil
                    }
                                        
                    users.removeAll { $0["uid"] as? String == user.uid }
                                        
                    let newUser = [
                        "id": user.id,
                        "uid": user.uid,
                        "email": user.email,
                        "friendRequests": user.friendRequests,
                        "friends": user.friends,
                        "displayName": user.displayName ?? "",
                        "latitude": user.latitude,
                        "longitude": user.longitude
                    ]
                    users.append(newUser)
                                        
                    transaction.updateData(["users": users], forDocument: groupRef)
                    
                    return nil
                }) { (_, error) in
                    if let error = error {
                        print("Error updating user location: \(error.localizedDescription)")
                    } else {
                        print("User location updated successfully.")
                    }
                }
            }
        }
    }
}
