//
//  FriendSheet.swift
//  will_prj
//
//  Created by 邱允聰 on 10/1/2025.
//

import SwiftUI

struct FriendSheet: View {
    let user: User
    let myUser: User
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: FriendListViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            vm.userImage?
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .padding(.top, 30)
                .foregroundStyle(.gray)
            
            Text(user.displayName ?? "null")
                .font(.title2)
                .bold()                        
            
            if vm.isLoading {
                ProgressView()
            } else {
                if vm.isFriend {
                    Button {
                        vm.navigateToProfile.toggle()                        
                        dismiss()
                    } label: {
                        HStack{
                            Image(systemName: "person.crop.circle.fill")
                            Text("Profile")
                        }
                        .profileButtonStyle()
                        .padding(.horizontal)
                    }

                    Button {
                        vm.checkExistingChat(myUser, user)
                    } label: {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Start Chat")
                        }
                        .profileButtonStyle()
                        .padding(.horizontal)
                    }
                } else if vm.hasReceivedRequest {
                    VStack(spacing: 10) {
                        Button {
                            vm.acceptFriendRequest(myUser, user)
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
                            vm.declineFriendRequest(myUser, user)
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
                } else if vm.hasPendingRequest {
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
                        vm.sendFriendRequest(myUser, user)
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
        .presentationDetents([.medium])
        .onAppear {
            vm.checkIfFriend(myUser, user)
            vm.checkPendingRequest(myUser, user)
            vm.checkReceivedRequest(myUser, user)
            vm.user = user
            vm.myUser = myUser
            vm.fetchImage(user.uid)
        }
        .onChange(of: vm.navigateToChat) { oldValue, newValue in
            dismiss()
        }
        .onChange(of: vm.navigateToProfile) { oldValue, newValue in
            dismiss()
        }
    }
}

#Preview {
    //    FriendSheet()
}
