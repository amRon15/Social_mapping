//
//  ChatListScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 25/12/2024.
//

import SwiftUI

struct ChatListScreen: View {
    @StateObject var vm = ChatListViewModel()
    
    var body: some View {
        NavigationStack{
            ScrollView(.vertical){
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
            .loadingBackground(vm.isLoadingChat)
        }
    }
}



#Preview {
    ChatListScreen()
}
