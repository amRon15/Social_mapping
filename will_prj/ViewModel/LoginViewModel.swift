//
//  LoginViewModel.swift
//  will_prj
//
//  Created by 邱允聰 on 22/12/2024.
//

import Foundation
import Firebase
import AuthenticationServices
import FirebaseAuth
import Security
import LocalAuthentication
import _PhotosUI_SwiftUI
import SwiftUICore
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    
    @Published var isLogin: Bool = false
    @Published var isLoggingIn: Bool = false
    private var isCreatingAc: Bool = false
    
    @Published var createAccountResult: String = ""
    
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var registerEmail: String = ""
    @Published var registerPassword: String = ""
    @Published var confirmPassword: String = ""
    
    let context = LAContext()
    @Published var isBiometricLogin: Bool = false
    @Published var isError: Bool = false
    @Published var biometricErrorMessage: String = ""
    @Published var isAuthenicated: Bool = false
    
    @Published var isEnterUserInfo: Bool = false
    @Published var avaterItem: PhotosPickerItem?
    @Published var avatarImage: Image?
    @Published var username: String = ""    
    
    let auth = Auth.auth()
    
    init(){
        if FirebaseAuthManager().isAuth(){
            self.isLogin = true
        } else{
            self.isLogin = false
        }
    }
    
    private let cloudinary = CloudinaryManager()
    
    func createAccount(){
        isCreatingAc = true
        if (confirmPassword == registerPassword){
            Auth.auth().createUser(withEmail: registerEmail, password: registerPassword) { authResult, error in
                if let error = error{
                    DispatchQueue.main.async {
                        self.createAccountResult = error.localizedDescription
                    }
                    return
                }
                
                self.email = self.registerEmail
                self.password = self.registerPassword
                self.isBiometricLogin = true
            }
        }else{
            self.createAccountResult = "Password does not match"
        }
    }
    
    @MainActor func saveUserInfo(){
        user?.displayName = username
        isLoggingIn = true
        if let user = user{
            FirestoreManager().saveUserData(user: user) { result in
                switch result {
                case .success:
                    self.uploadImage()
                case .failure(let failure):
                    print("save user failed: \(failure.localizedDescription)")
                }
            }
        }
    }
    
    func saveAccountToKeychain(){
        KeychainManager().storePassword(account: email, password: password)
        self.isBiometricLogin = false        
        self.isEnterUserInfo = true
        loginWithEmail()
    }
    
    func changeProfilePicture(){
        Task{
            if let loaded = try? await avaterItem?.loadTransferable(type: Image.self){
                DispatchQueue.main.async {
                    self.avatarImage = loaded
                }
            }
        }
    }
    
    @MainActor func uploadImage(){
        if let data = ImageRenderer(content: avatarImage).uiImage?.jpegData(compressionQuality: 0.8){
            if let userId = user?.uid{
                cloudinary.uploadImage(data: data, userId: userId) { result in
                    switch result {
                    case .success:
                        self.isLogin = true
                        self.isEnterUserInfo = false
                        self.isLoggingIn = false
                        print("Upload image success")
                    case .failure(let failure):
                        print("Upload image failed: \(failure)")
                    }
                }
            }
        }
    }
    
    // MARK: - Email & Password Login
    func loginWithEmail() {
        isLoggingIn = true
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoggingIn = false
                }
                return
            }
            
            guard let firebaseUser = result?.user else {
                DispatchQueue.main.async {
                    self?.errorMessage = "User not found."
                    self?.isLoggingIn = false
                }
                return
            }
            
            self?.user = User(
                id: UUID().uuidString,
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                displayName: firebaseUser.displayName ?? "",
                latitude: 0,
                longitude: 0
            )
            
            DispatchQueue.main.async {
                self?.isLoggingIn = false
                if self?.isCreatingAc == true{
                    self?.isLogin = false
                } else{
                    self?.isLogin = true
                    self?.email = ""
                    self?.password = ""
                }
            }
        }
    }
    
    func checkPolicy() {
        var error : NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                     error: &error) {
            self.isError = false
        } else {
            if let err = error {
                self.isError = true
                switch err.code {
                case LAError.Code.biometryNotEnrolled.rawValue:
                    self.biometricErrorMessage = "not enrolled"
                case LAError.Code.passcodeNotSet.rawValue:
                    self.biometricErrorMessage = "passcode not set"
                case LAError.Code.biometryNotAvailable.rawValue:
                    self.biometricErrorMessage = "not available"
                default:
                    self.biometricErrorMessage = "Unknown Error"
                }
            }
        }
    }
    
    func evaluatePolicy() {
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "Authentication is required", reply: {
            success, error in
               
            DispatchQueue.main.async {
                if let error = error {
                    self.isError = true
                    self.biometricErrorMessage = "Cannot login"
                } else {
                    self.bioMetricLogin()
                    self.isError = false
                    self.isAuthenicated = true
                }
            }
        })
    }
    
    func bioMetricLogin(){
        if let email = UserDefaults().string(forKey: "UserEmail"){
            if let password = KeychainManager().retreivePassword(email){
                self.email = email
                self.password = password
                loginWithEmail()
            } else{
                biometricErrorMessage = "Not register yet"
            }
        } else{
            biometricErrorMessage = "Not register yet"
        }
    }
    
    // MARK: - Apple Sign-In
    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential, completion: @escaping (Bool) -> Void) {
        guard let idToken = credential.identityToken, let idTokenString = String(data: idToken, encoding: .utf8) else {
            self.errorMessage = "Unable to fetch identity token."
            completion(false)
            return
        }
        
        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: "")
        
        
        auth.signIn(with: firebaseCredential) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
                return
            }
            
            guard let firebaseUser = result?.user else {
                DispatchQueue.main.async {
                    self?.errorMessage = "User not found."
                    completion(false)
                }
                return
            }
            
            self?.user = User(
                id: UUID().uuidString,
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                displayName: firebaseUser.displayName,
                latitude: 0,
                longitude: 0
            )
            
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    // MARK: - Logout
    func logout() {
        do {
            try auth.signOut()
            DispatchQueue.main.async {
                self.user = nil
                self.isLogin = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
