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
            //                .mapStyle(.(elevation: .realistic))
            //                .overlay {
            //                    HStack{
            //                        Button {
            //                            withAnimation(.smooth) {
            //                                //                            vm.isSearching.toggle()
            //                            }
            //                        } label: {
            //                            Image(systemName: "magnifyingglass")
            //                                .font(.title)
            //                                .foregroundStyle(.white)
            //                                .padding()
            //                                .background(RoundedRectangle(cornerRadius: 20).fill(.black))
            //                        }
            //                    }
            //                    .padding(30)
            //                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            //                }
            
        }
        .toolbar(.hidden)
        .frame(maxHeight: .infinity)
        .sheet(isPresented: $ShowOtherProfile) {
            if let user = SelectedUser {
                UserProfileSheet(user: user, myUser: vm.myUser!, userImage: vm.nearbyUserImage[user.uid])
            }
        }
        .onDisappear{
            vm.stopUpdateUserLocation()
        }
    }
    
    //    var searchBar: some View{
    //        VStack{
    //            TextField("", text: $vm.searchText)
    //                .padding(.horizontal)
    //                .padding(.trailing, 20)
    //                .font(.title2)
    //                .padding(.vertical, 15)
    //                .overlay(alignment: .trailing) {
    //                    if vm.isSearching{
    //                        Button {
    //                            vm.searchText = ""
    //                        } label: {
    //                            Image(systemName: "xmark")
    //                                .padding(.trailing)
    //                                .foregroundStyle(.gray)
    //                        }
    //
    //                    }
    //                }
    //                .frame(width: vm.isSearching ? .infinity : .zero)
    //                .background(RoundedRectangle(cornerRadius: 20).fill(.white))
    //                .overlay(RoundedRectangle(cornerRadius: 20).stroke(lineWidth: 2).foregroundStyle(.black))
    //                .autocorrectionDisabled()
    //        }
    //    }
}

struct UserProfileSheet: View {
    let user: User
    let myUser: User
    let userImage: Image?
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToChat = false
    @State private var chatId: String?
    @State private var isLoading = false
    
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
                    Button {
                        startChat()
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
    }
    
    private func startChat() {
        isLoading = true
        let firestoreManager = FirestoreManager()
        
        // Create initial message
        let message = Message(
            id: UUID().uuidString,
            text: "",
            user: user,
            dateCreated: Date()
        )
        
        // Send initial message to create chat
        firestoreManager.sendMessage(
            chatId: nil,
            participants: [myUser, user],
            message: message
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let newChatId):
                chatId = newChatId
                navigateToChat = true
            case .failure(let error):
                print("Error creating chat: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    MapScreen()
}
