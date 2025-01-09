//
//  MapViewModel.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import Foundation
import MapKit
import _MapKit_SwiftUI
import CoreLocation
import Combine
import FirebaseAuth
import SwiftUI

class MapViewModel: NSObject, ObservableObject {
    let user = Auth.auth().getUserID()
    //    @Published var userLocation: CLLocation?
    private let locationManager = CLLocationManager()
    private let firestoreManager = FirestoreManager()
    private var timer: Timer?
    
    @Published var userImage: Image?
    @Published var myUser: User?
    @Published var nearbyUser: [User] = []
    @Published var nearbyUserImage: [String: Image] = [:]
    
    @Published var selectedUser: User?
    @Published var showOtherProfile: Bool = false
    
    @Published var showFriendList: Bool = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        fetchUserImage()
        if let user = user{
            getUserInfo(user)
        }
        startUpdateUserLocation()
    }
    
    func startUpdateUserLocation(){
        updateUserLocation()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateUserLocation()
            self.fetchNearbyUsers()
        }
    }
    
    func stopUpdateUserLocation(){
        timer?.invalidate()
    }
    
    func getUserInfo(_ userId: String){
        FirestoreManager().fetchUserData(userId) { result in
            switch result {
            case .success(let success):
                self.myUser = success
                self.fetchNearbyUsers()
            case .failure(let failure):
                print("Fetch user failed: \(failure)")
            }
        }
    }
    
    func fetchUserImage(){
        if let userId = FirestoreManager().user{
            CloudinaryManager().fetchImage(publicId: userId) { image in
                DispatchQueue.main.async {
                    self.userImage = image
                }
            }
        }
    }
    
    func fetchNearbyUserImage(){
        for user in nearbyUser {
            CloudinaryManager().fetchImage(publicId: user.uid) { image in
                DispatchQueue.main.async {
                    self.nearbyUserImage[user.uid] = image
                }
            }
        }
    }
    
    func updateUserLocation() {
        guard let user = myUser else { return }
        firestoreManager.updateUserLocation(location: CLLocation(latitude: user.latitude, longitude: user.longitude)) { result in
            switch result {
            case .success():
                print("User location updated successfully.")
            case .failure(let error):
                print("Failed to update user location: \(error.localizedDescription)")
            }
        }
        
        if let uId = myUser?.uid{
            firestoreManager.getUserLocation(userId: uId) { result in
                switch result {
                case .success(let data):
                    self.myUser?.latitude = data.coordinate.latitude
                    self.myUser?.longitude = data.coordinate.longitude
                case .failure(let failure):
                    print("Get user location failed: \(failure.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Fetch Nearby Users
    func fetchNearbyUsers() {
        guard let user = myUser else { return }
        firestoreManager.fetchNearbyUsers(currentLocation: CLLocation(latitude: user.latitude, longitude: user.longitude)) { result in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self.nearbyUser = users
                    self.fetchNearbyUserImage()
                    print("Fetch nearby successful")
                }
            case .failure(let error):
                print("Failed to fetch nearby users: \(error.localizedDescription)")
            }
        }
    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        DispatchQueue.main.async {
            self.myUser?.latitude = newLocation.coordinate.latitude
            self.myUser?.longitude = newLocation.coordinate.longitude
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}
