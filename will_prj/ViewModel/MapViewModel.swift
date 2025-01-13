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
    private let locationManager = CLLocationManager()
    private let firestoreManager = FirestoreManager()
    private var timer: Timer?
    
    @Published var region: MapCameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
    @Published var userImage: Image?
    @Published var myUser: User?
    @Published var friends: [User] = []
    @Published var nearbyUser: [User] = []
    @Published var nearbyUserImage: [String: Image] = [:]
    
    
    @Published var selectedUser: User?
    @Published var showOtherProfile: Bool = false
    
    @Published var showFriendList: Bool = false
    
    @Published var groupDistances: [String: [String: Double]] = [:]
    @Published var errorMessage: String? = nil
    
    
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
    } 
    
    func startUpdateUserLocation(){
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateUserLocation()
            self.fetchNearbyUsers()
        }
    }
    
    func stopUpdateUserLocation(){
        timer?.invalidate()
    }
    
    func getUserInfo(_ userId: String){
        DispatchQueue.main.async{
            self.firestoreManager.fetchUserData(userId) { result in
                switch result {
                case .success(let success):
                    self.myUser = success
                    self.region = .region(MKCoordinateRegion(center: CLLocationCoordinate2D().location(success), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                    self.loadFriends()
                case .failure(let failure):
                    print("Fetch user failed: \(failure)")
                }
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
    
    func fetchNearbyUserImage(_ users: [User]){
        for user in users{
            CloudinaryManager().fetchImage(publicId: user.uid) { image in
                DispatchQueue.main.async {
                    self.nearbyUserImage[user.uid] = image
                }
            }
        }
    }
    
    func updateUserLocation() {
        guard let user = myUser else { return }
        DispatchQueue.main.async{
            self.firestoreManager.updateUserLocation(location: CLLocation(latitude: user.latitude, longitude: user.longitude)) { result in
                switch result {
                case .success():
                    print("User location updated successfully.")
                case .failure(let error):
                    print("Failed to update user location: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Fetch Nearby Users
    func fetchNearbyUsers() {
        guard let user = myUser else { return }
        DispatchQueue.main.async{
            self.firestoreManager.fetchNearbyUsers(currentLocation: CLLocation(latitude: user.latitude, longitude: user.longitude)) { result in
                switch result {
                case .success(let users):
                    DispatchQueue.main.async {
                        self.nearbyUser = users
                        self.userInMap()
                    }
                case .failure:
                    print("Failed to fetch nearby users")
                }
            }
        }
    }
    
    func loadFriends() {
        guard let user = myUser else { return }
        DispatchQueue.main.async{
            self.firestoreManager.fetchUserInfo(uids: user.friends) { result in
                switch result {
                case .success(let users):
                    self.friends = users
                    self.fetchNearbyUsers()
                    self.startUpdateUserLocation()
                case .failure(let error):
                    print("Error loading friends: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func userInMap(){
        var user : [User] = []
        let nearByUser = Set(self.nearbyUser), friends = Set(self.friends)
        user.append(contentsOf: nearByUser.subtracting(friends))
        self.nearbyUser = user.filter{$0.uid != self.user}
        
        self.fetchNearbyUserImage(self.nearbyUser)
    }
    
    func getUserImage(_ user: User) -> Image{
        return nearbyUserImage[user.uid] ?? Image(systemName: "person.circle.fill")
    }
    
    func moveToRegion(_ user: User){
        DispatchQueue.main.async {
            self.region = .region(MKCoordinateRegion(center: CLLocationCoordinate2D().location(user), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        }
    }
    
    func calculateDistances(users: [User], destination: CLLocationCoordinate2D) -> [String: Double] {
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        var distances: [String: Double] = [:]
        
        for user in users {
            let userLocation = CLLocation(latitude: user.latitude, longitude: user.longitude)
            let distance = userLocation.distance(from: destinationLocation) // 單位為米
            distances[user.displayName ?? user.email] = distance
        }
        return distances
    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        DispatchQueue.main.async {
            let latitude = newLocation.coordinate.latitude
            let longitude = newLocation.coordinate.longitude
            self.myUser?.latitude = latitude
            self.myUser?.longitude = longitude
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}
