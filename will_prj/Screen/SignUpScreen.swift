//
//  SignUpScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 26/12/2024.
//

import SwiftUI
import _PhotosUI_SwiftUI

struct SignUpScreen: View {
    @EnvironmentObject var vm: LoginViewModel
    var body: some View {
        VStack{
            Text("Create your Account")
                .font(.title2)
            VStack(spacing: 20){
                TextField("Email", text: $vm.registerEmail)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $vm.registerPassword)
                SecureField("Confirm Password", text: $vm.confirmPassword)
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            
            Button{
                vm.createAccount()
            }label: {
                Text("Create Account")
                    .profileButtonStyle()
            }
            .padding(.top)
            
            Text("\(vm.createAccountResult)")
                .foregroundStyle(.pink)
                .padding(.top)
        }
        .padding(.horizontal)
        .alert("Do you want to login with biometric?", isPresented: $vm.isBiometricLogin) {
            Button("No", role: .cancel){
                vm.isEnterUserInfo = true
                vm.saveAccountToKeychain()
                vm.loginWithEmail() }
            Button("Yes", role: .destructive){ vm.saveAccountToKeychain() }
        }
        .sheet(isPresented: $vm.isEnterUserInfo, content: {userInfo})
        
    }
     
    var userInfo: some View{
        VStack(spacing: 20){
            if vm.isLoggingIn{
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2, anchor: .center)
            } else {
                VStack{
                    PhotosPicker(selection: $vm.avaterItem, matching: .images) {
                        VStack{
                            Label{} icon: {
                                VStack{
                                    Image(systemName: "photo")
                                        .font(.system(size: 80))
                                        .foregroundStyle(.gray)
                                    Text("Select Icon")
                                        .font(.caption)
                                }
                            }
                            .labelStyle(.titleAndIcon)
                            .font(.title)
                            .overlay {
                                vm.avatarImage?
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 200)
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                            }
                            .frame(width: 200, height: 200)
                            .background{
                                Circle()
                                    .fill(.gray.opacity(0.5))
                            }
                            
                        }
                        
                    }
                }
                .onChange(of: vm.avaterItem) {
                    vm.changeProfilePicture()
                }
                
                TextField("Username", text: $vm.username)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                Button {
                    vm.saveUserInfo()
                } label: {
                    Text("Confirm")
                        .profileButtonStyle()
                }
            }
        }
        .padding()
        .interactiveDismissDisabled()
    }
}

#Preview {
        SignUpScreen()
//    UserInfo()
}
