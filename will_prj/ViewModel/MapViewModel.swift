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
    @Published var userLocation: CLLocation?
    @Published var nearbyUsers: [UserLocation] = []
    private let locationManager = CLLocationManager()
    private let firestoreManager = FirestoreManager()
    private var timer: Timer?
    
    @Published var userImage: Image?
    @Published var myUser: User?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        fetchUserImage()
        getUserInfo()
        startUpdateUserLocation()
    }
    
    func startUpdateUserLocation(){
        updateUserLocation()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateUserLocation()
        }
    }
    
    func stopUpdateUserLocation(){
        timer?.invalidate()
    }
    
    func getUserInfo(){
        FirestoreManager().fetchUserData { result in
            switch result {
            case .success(let success):
                self.myUser = success
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
        
    func updateUserLocation() {        
        guard let location = userLocation else { return }
        firestoreManager.updateUserLocation(location: location) { result in
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
    
    //    // MARK: - Fetch Nearby Users
    //    func fetchNearbyUsers(radiusInMeters: Double) {
    //        guard let location = userLocation else { return }
    //        firestoreManager.fetchNearbyUsers(currentLocation: location, radiusInMeters: radiusInMeters) { result in
    //            switch result {
    //            case .success(let users):
    //                DispatchQueue.main.async {
    //                    self.nearbyUsers = users
    //                }
    //            case .failure(let error):
    //                print("Failed to fetch nearby users: \(error.localizedDescription)")
    //            }
    //        }
    //    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = newLocation
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}
