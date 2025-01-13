//
//  FriendListView.swift
//  will_prj
//
//  Created by 邱允聰 on 9/1/2025.
//
import SwiftUI

struct FriendListView: View {
    @EnvironmentObject var vm: FriendListViewModel
    @EnvironmentObject var mapVm: MapViewModel
    @Environment(\.dismiss) private var dismiss
        
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
                                vm.selectedFriend = friend
                                vm.showFriendSheet = true
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
            .sheet(isPresented: $vm.showFriendSheet) {
                if let friend = vm.selectedFriend, let currentUser = vm.currentUser {
                    FriendSheet(user: friend, myUser: currentUser)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onChange(of: mapVm.region) {
            dismiss()
        }
        .onChange(of: vm.navigateToChat) {
            dismiss()
        }
    }
}



#Preview {
    FriendListView()
}
