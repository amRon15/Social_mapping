//
//  LoginScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 21/12/2024.
//

import SwiftUI
import AuthenticationServices

struct LoginScreen: View {
        @EnvironmentObject var vm: LoginViewModel
//    @StateObject var vm: LoginViewModel = LoginViewModel()
    var body: some View {
        NavigationStack{
            VStack{
                Text("Login to your Account")
                    .font(.title2)
                VStack(spacing: 20){
                    TextField("Email", text: $vm.email)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $vm.password)
                }
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                
                VStack(spacing: 20){
                    Button{
                        vm.loginWithEmail()
                    }
                    label: {
                        Text("Login")
                            .profileButtonStyle()
                    }
                    
                    Text("\(vm.errorMessage ?? "")")
                        .foregroundStyle(.pink)
                        
                    HStack(alignment: .center){
                        Rectangle()
                            .frame(maxWidth: .infinity, maxHeight: 1)
                            .foregroundStyle(.gray.opacity(0.6))
                        Text("Or sign up with")
                            .foregroundStyle(.gray)
                            .font(.caption)
                        Rectangle()
                            .frame(maxWidth: .infinity, maxHeight: 1)
                            .foregroundStyle(.gray.opacity(0.6))
                    }
                    .padding(.vertical, 10)
                    .padding(.top, 10)
                    Button {
                        vm.checkPolicy()
                        vm.evaluatePolicy()
                    } label: {
                        VStack{
                            Image(systemName: "faceid")
                                .resizable()
                                .frame(width: 50, height: 50)
                            Text("Biometric")
                                .font(.caption)
                        }
                    }
                    
                    NavigationLink {
                        SignUpScreen()
                    } label: {
                        Text("Sign up with email")
                    }
                    .padding(.top, 20)
                }
                .padding(.vertical)
                
                Text("\(vm.biometricErrorMessage)")
                    .foregroundStyle(.pink)
            }
        }
        .padding(.horizontal)
        .loadingBackground(vm.isLoggingIn)
    }
}

#Preview {
//    LoginScreen()
}
