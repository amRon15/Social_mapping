//
//  MapScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import SwiftUI
import MapKit

struct MapScreen: View {
    @StateObject var vm: MapViewModel = MapViewModel()
    @State private var SelectedUser: User?
    @State private var ShowOtherProfile = false
    
    var body: some View {
        ZStack{
            VStack{
                Map{
                    Annotation(vm.myUser?.displayName ?? "My User", coordinate: CLLocationCoordinate2D().location(vm.myUser)){
                        vm.userImage?
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                    MapCircle(center: CLLocationCoordinate2D().location(vm.myUser), radius: 500)
                        .foregroundStyle(.blue.opacity(0.3))
                        .mapOverlayLevel(level: .aboveRoads)
                    
                    ForEach(vm.nearbyUser) { user in
                        if user.uid != vm.myUser?.uid {
                            Annotation(user.displayName ?? "Anonymous", coordinate: CLLocationCoordinate2D().location(user)) {
                                Button {
                                    SelectedUser = user
                                    ShowOtherProfile = true
                                } label: {
                                    if let userImage = vm.nearbyUserImage[user.uid] {
                                        userImage
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                            .shadow(radius: 3)
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.gray)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                            .shadow(radius: 3)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            VStack {
                HStack {
                    Spacer()
                    FriendListButton()
                        .padding()
                }
                Spacer()
            }
            .toolbar(.hidden)
            .frame(maxHeight: .infinity)
            .sheet(isPresented: $ShowOtherProfile) {
                if let user = SelectedUser {
                    FriendSheet(user: user, myUser: vm.myUser!, userImage: vm.nearbyUserImage[user.uid])
                }
            }
            .onDisappear{
                vm.stopUpdateUserLocation()
            }
        }
    }
}

struct FriendSheet: View {
    let user: User
    let myUser: User
    let userImage: Image?
    @Environment(\.dismiss) private var dismiss
    @State private var chatId: String?
    @State private var isLoading = false
    @State private var navigateToChat = false
    @State private var isFriend = false
    @State private var hasPendingRequest = false
    @State private var hasReceivedRequest = false
    private let firestoreManager = FirestoreManager()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                userImage?
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .padding(.top, 30)
                
                Text(user.displayName ?? "null")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                } else {
                    if isFriend {
                        Button {
                            checkExistingChat()
                        } label: {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Start Chat")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    } else if hasReceivedRequest {
                        VStack(spacing: 10) {
                            Button {
                                acceptFriendRequest()
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Accept Friend Request")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                            
                            Button {
                                declineFriendRequest()
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.minus")
                                    Text("Decline")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    } else if hasPendingRequest {
                        HStack {
                            Image(systemName: "clock.fill")
                            Text("Friend Request Sent")
                        }
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    } else {
                        Button {
                            sendFriendRequest()
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Add Friend")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .foregroundColor(.blue)
                        .padding(.bottom, 30)
                }
            }
            .navigationDestination(isPresented: $navigateToChat) {
                if let chatId = chatId {
                    ChatScreen(user: myUser, chatUser: user, chatid: chatId)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            checkIfFriend()
            checkPendingRequest()
            checkReceivedRequest()
        }
    }
    
    private func checkIfFriend() {
        isFriend = myUser.friends.contains(user.uid)
    }
    
    private func checkPendingRequest() {
        isLoading = true
        firestoreManager.checkPendingFriendRequest(from: myUser.uid, to: user.uid) { result in
            isLoading = false
            switch result {
            case .success(let isPending):
                hasPendingRequest = isPending
            case .failure(let error):
                print("Error checking pending request: \(error.localizedDescription)")
                hasPendingRequest = false
            }
        }
    }
    
    private func checkReceivedRequest() {
        hasReceivedRequest = myUser.friendRequests.contains(user.uid)
    }
    
    private func acceptFriendRequest() {
        isLoading = true
        firestoreManager.acceptFriendRequest(currentUserId: myUser.uid, requesterId: user.uid) { error in
            isLoading = false
            if let error = error {
                print("Error accepting friend request: \(error.localizedDescription)")
            } else {
                isFriend = true
                hasReceivedRequest = false
                dismiss()
            }
        }
    }
    
    private func declineFriendRequest() {
        isLoading = true
        firestoreManager.declineFriendRequest(currentUserId: myUser.uid, requesterId: user.uid) { error in
            isLoading = false
            if let error = error {
                print("Error declining friend request: \(error.localizedDescription)")
            } else {
                hasReceivedRequest = false
                dismiss()
            }
        }
    }
    
    private func sendFriendRequest() {
        isLoading = true
        firestoreManager.sendFriendRequest(from: myUser.uid, to: user.uid) { error in
            isLoading = false
            if let error = error {
                print("Error sending friend request: \(error.localizedDescription)")
            } else {
                hasPendingRequest = true
            }
        }
    }
    
    private func checkExistingChat() {
        isLoading = true
        let firestoreManager = FirestoreManager()
        
        firestoreManager.checkExistingChat(between: [myUser, user]) { result in
            switch result {
                case .success(let existingChatId):
                    self.chatId = existingChatId
                    self.isLoading = false
                    self.navigateToChat = true
                case .failure(_):
                    startChat()
            }
        }
    }
    
    private func startChat() {
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
}
struct FriendListButton: View {
    @State private var showFriendList = false
    @StateObject private var vm = FriendListViewModel()
    
    var body: some View {
        Button {
            showFriendList.toggle()
        } label: {
            Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .sheet(isPresented: $showFriendList) {
            FriendListView(vm: vm)
        }
    }
}

struct FriendListView: View {
    @ObservedObject var vm: FriendListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFriend: User?
    @State private var showFriendSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Friend Requests") {
                    if vm.friendRequests.isEmpty {
                        Text("No pending requests")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(vm.friendRequests) { user in
                            HStack {
                                Text(user.displayName ?? "Anonymous")
                                Spacer()
                                Button("Accept") {
                                    vm.acceptFriendRequest(from: user)
                                }
                                .buttonStyle(.bordered)
                                Button("Decline") {
                                    vm.declineFriendRequest(from: user)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }
                    }
                }
                
                Section("Friends") {
                    if vm.friends.isEmpty {
                        Text("No friends yet")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(vm.friends) { friend in
                            Button {
                                selectedFriend = friend
                                showFriendSheet = true
                            } label: {
                                Text(friend.displayName ?? "Anonymous")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showFriendSheet) {
                if let friend = selectedFriend, let currentUser = vm.currentUser {
                    FriendSheet(user: friend, myUser: currentUser, userImage: nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}


#Preview {
    MapScreen()
}
