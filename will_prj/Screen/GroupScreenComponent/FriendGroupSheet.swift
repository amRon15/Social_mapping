//
//  FriendGroupSheet.swift
//  will_prj
//
//  Created by 邱允聰 on 11/1/2025.
//

import SwiftUI

struct FriendGroupSheet: View {
    @EnvironmentObject var vm: FriendListViewModel
    @EnvironmentObject var grpVm: GroupViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack{
            ForEach(vm.friends){ friend in
                VStack{
                    HStack{
                        if grpVm.containFriend(friend){
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.green)
                                .padding(.trailing, 5)
                        } else{
                            Image(systemName: "circlebadge")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 5)
                        }
                        
                        vm.getFriendImage(friend)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                        Text("\(friend.displayName ?? "Annoymous")")
                            .foregroundStyle(.white)
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    Divider()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture {
                    grpVm.selectFriend(friend)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 20)
        .navigationTitle("Location group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            ToolbarItem(placement: .confirmationAction) {
                Button("Next", action:{
                    dismiss()
                    grpVm.createGroupNavigation()
                })
            }
        }
    }
}

#Preview {
    FriendGroupSheet()
}
