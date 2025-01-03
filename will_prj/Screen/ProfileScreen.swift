//
//  ProfileScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import SwiftUI

struct ProfileScreen: View {
    @StateObject var vm: ProfileViewModel = ProfileViewModel()
    @EnvironmentObject var loginVm: LoginViewModel
    var body: some View {
        NavigationStack{
            ScrollView(.vertical) {
                VStack{
                    vm.userImage?
                        .resizable()
                        .frame(width: 200, height: 200)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                    Text(vm.user?.displayName ?? "Annoymous")
                        .font(.title2)
                    HStack{
                        Button("Add") {
                            
                        }
                        .profileButtonStyle()
                        Button("Message") {
                            
                        }
                        .profileButtonStyle()
                    }
                    .padding(.horizontal)
                    
                    Button {
                        vm.isLogout.toggle()
                    } label: {
                        Text("Logout")
                            .profileButtonStyle()
                            .padding(.horizontal)
                    }

                    Divider()
                        .padding(.top, 20)
                    LazyVGrid(columns: vm.columns){
//                        ForEach(vm.userPosts, id: \.self){post in
//                            
//                        }
                    }
                    Spacer()
                }
                .alert("Are you sure to logout?", isPresented: $vm.isLogout) {
                    Button("No", role: .cancel){
                        vm.isLogout.toggle()
                    }
                    Button("Yes", role: .destructive){ loginVm.logout() }
                }
                .toolbar{
                    ToolbarItem(placement: .confirmationAction) {
                        Image(systemName: "gearshape")                            
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileScreen()
}
