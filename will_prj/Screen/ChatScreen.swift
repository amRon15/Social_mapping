//
//  ChatScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import SwiftUI

struct ChatScreen: View {
    @StateObject var vm: ChatViewModel
    
    init(user: User, chatUser: User, chatid: String?){
        _vm = StateObject(wrappedValue: ChatViewModel(user: user, chatUser: chatUser, chatId: chatid))
    }
    
    var body: some View {
        VStack {
            ScrollView(.vertical){
                VStack{
                    if vm.errorMessage != ""{
                        Text("\(vm.errorMessage)")
                            .foregroundStyle(.pink)
                    }
                    ForEach(vm.messages){message in
                        if message.isMessageOwner{
                            HStack{
                                Text(message.text)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 20).fill(.blue))
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        } else{
                            HStack{
                                Text(message.text)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 20).fill(.gray))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            HStack{
                TextField("Message...", text: $vm.messageText)                    
                    .padding(.vertical)
                    .padding(.leading)
                    .background(Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                if vm.messageText.trimmingCharacters(in: .whitespacesAndNewlines) != ""{
                    Button {
                        vm.sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundStyle(.black)
                            .padding(.horizontal)
                            .background{
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 50, height: 50)
                            }
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 20).fill(.gray))
            .padding()
        }
        .onTapGesture {
            hideKeyboard()
        }
        .toolbar{
            ToolbarItem(placement: .principal) {
                HStack{
                    if vm.chatUserImage == nil{
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                    } else{
                        vm.chatUserImage?
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    }
                    Text("\(vm.chatUser.displayName ?? "Annoymous")")
                }
            }
        }
        .loadingBackground(vm.isLoadingChat)
    }
}



#Preview {
    let user = User(id: "1", uid: "1", email: "1", latitude: 0, longitude: 0)
    ChatScreen(user: user, chatUser: user, chatid: "2")
}
