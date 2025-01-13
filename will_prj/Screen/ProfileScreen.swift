//
//  ProfileScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import SwiftUI

struct ProfileScreen: View {
    @StateObject var vm: ProfileViewModel
    @EnvironmentObject var loginVm: LoginViewModel
    
    init(_ userId: String){
        _vm = StateObject(wrappedValue: ProfileViewModel(userId))
    }
    
    var body: some View {
        NavigationStack{
            VStack{
                vm.userImage?
                    .resizable()
                    .frame(width: 200, height: 200)
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                Text(vm.user?.displayName ?? "Annoymous")
                    .font(.title2)
                VStack(spacing: 10){
                    Button {
                        vm.showAlert.toggle()
                    } label: {
                        Label("Biometric login", systemImage: "faceid")
                            .profileButtonStyle()
                            .padding(.horizontal)
                    }

                    Button {
                        vm.isLogout.toggle()
                    } label: {
                        Text("Logout")
                            .profileButtonStyle()
                            .padding(.horizontal)
                    }
                }
            }
            .alert("Are you sure to logout?", isPresented: $vm.isLogout) {
                Button("Cancel", role: .cancel){
                    vm.isLogout.toggle()
                }
                Button("Confirm", role: .destructive){ loginVm.logout() }
            }
            .alert("Enable biometric login?", isPresented: $vm.showAlert){
                Button("Cancel", role: .cancel){
                    vm.showAlert.toggle()
                }
                Button("Confirm") {
                    vm.showAlert.toggle()
                    loginVm.checkPolicy()
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}

#Preview {
    //    ProfileScreen()
}
