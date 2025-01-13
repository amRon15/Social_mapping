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
                    ForEach(vm.messages){message in
                        if message.isMessageOwner{
                            HStack{
                                Text(message.text)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 20).fill(.blue))
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        } else{
                            if message.text.trimmingCharacters(in: .whitespacesAndNewlines) != ""{
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
        .loadingBackground(vm.isLoadingChat)
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
    }
}
