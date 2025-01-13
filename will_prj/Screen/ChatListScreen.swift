//
//  ChatListScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 25/12/2024.
//

import SwiftUI

struct ChatListScreen: View {
    @StateObject var vm: ChatListViewModel = ChatListViewModel()
    
    var body: some View {
        NavigationStack{
            ScrollView(.vertical){
                if vm.isLoadingChat{
                    ProgressView()
                } else{
                    VStack{
                        ForEach(vm.chats) { chat in
                            NavigationLink {
                                ChatScreen(user: vm.currentUser!, chatUser: vm.getUser(chat), chatid: chat.documentId)
                            } label: {
                                HStack{
                                    vm.getUserImage(chat)
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        .foregroundStyle(.white)
                                    VStack(alignment: .leading){
                                        HStack{
                                            Text("\(vm.getUserName(chat))")
                                                .foregroundStyle(.white)
                                                .font(.title3)
                                            Text("\(vm.toDate(chat.lastMessage.dateCreated))")
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                                .font(.caption)
                                        }
                                        HStack{
                                            Text("\(vm.messagePrefix(for: chat))")
                                            Text("\(chat.lastMessage.text)")
                                        }
                                    }
                                    .foregroundStyle(.gray)
                                    .padding(.leading, 10)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            Divider()
                        }
                    }
                    .navigationTitle("Chat")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .toolbar{
                ToolbarItem(placement: .confirmationAction) {
                    Button(action:{
                        vm.showFriendList.toggle()
                        vm.loadFriends()
                    }, label:{
                        Image(systemName: "plus")
                    })
                }
            }
            .sheet(isPresented: $vm.showFriendList) {
                friendSheet
            }
            .navigationDestination(isPresented: $vm.isNavigateToChat) {
                if let currentUser = vm.currentUser, let user = vm.selectedUser{
                    ChatScreen(user: currentUser, chatUser: user, chatid: "")
                }
            }
        }
    }
    
    var friendSheet: some View{
        List {
            Section("Friends"){
                if vm.friends.isEmpty{
                    Text("No friend yet")
                        .foregroundStyle(.gray)
                }else{
                    ForEach(vm.friends) { friend in
                        Button {
                            vm.navigateToChat(friend)
                        } label: {
                            HStack{
                                vm.getFriendsImage(friend)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                Text("\(friend.displayName ?? "Annoymous")")
                                    .foregroundStyle(.primary)
                                    .font(.title3)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .loadingBackground(vm.isLoadingFriends)
    }
}



#Preview {
    ChatListScreen()
}
