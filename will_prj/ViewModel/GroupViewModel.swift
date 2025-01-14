//
//  GroupViewModel.swift
//  will_prj
//
//  Created by 邱允聰 on 12/1/2025.
//

import Foundation
import MapKit
import SwiftUI
import CoreLocation
import Firebase
import FirebaseFirestore

class GroupViewModel: ObservableObject{
    @Published var region: MapCameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
    @Published var user: User?
    @Published var showDeleteAlert: Bool = false
    @Published var showErrMessage: Bool = false
    
    @Published var errorMessage: String = ""
    
    @Published var groups: [GroupModel] = []
    
    @Published var selectedFriends: [String: User] = [:]
    @Published var createGroupMode: Bool = false
    @Published var selectedLocation: CLLocationCoordinate2D? = nil
    @Published var isUploadingGroup: Bool = false
    @Published var message: String = ""
    
    @Published var showAlert: Bool = false
    @Published var groupName: String = ""
    @Published var groupDestination: CLLocationCoordinate2D? = nil
    var memberDistance: [String: String] = [:]
    
    @Published var selectedGroup: GroupModel?
    @Published var isNavigateToDetail: Bool = false
    
    @Published var membersImage: [String: Image] = [:]
    @Published private var memberActiveIndices: [String: Int] = [:]
    @Published var memberInt: Int = 0
    @Published var time: Int = 0
    @Published var memberTimer: Timer?
    @Published private var timer: Timer?
    
    @Published var showMap: Bool = false
    
    @Published var updateTimer: Timer?
    
    @Published var activityTimer: Timer?
    private var index: Int = 0
    private var fireStoreManager: FirestoreManager = FirestoreManager()
    private var groupListener: ListenerRegistration?
    
    static let shared = GroupActivityManager()
    
    @Environment(\.dismiss) var dismiss

    init(){
        fetchGroup()
    }
    
    func getRegion(_ region: MapCameraPosition){
        self.region = region
    }
    
    func startUpdate(){
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { _ in
            self.updateLocation()
        })
    }
    
    func getGrpActivityInfo(){
        if let members = selectedGroup?.users{
            for member in members {
                memberDistance[member.displayName ?? "Member"] = self.calculateDistance(member)
            }
        }
        guard let locationDict = selectedGroup?.destination["destination"],
              let latitude = locationDict["latitude"],
              let longitude = locationDict["longitude"] else { return }
        
        groupDestination = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
      
    func observeGroup(){
        if let id = selectedGroup?.id{
            self.groupListener = fireStoreManager.observeGroup(id) { result in
                switch result {
                case .success(let success):
                    self.selectedGroup = success
                    self.getGrpActivityInfo()
                    self.fetchUserImage()
                    self.startUpdate()
                    self.updateActivity()
                    self.startActivity()
                    self.startAnimation()
                    self.finishGroup()
                case .failure(let failure):
                    print("Failed to observe group: \(failure.localizedDescription)")
                }
            }
        }
    }
    
    func stopObservingGroup() {
        fireStoreManager.stopObservingGroup(listener: groupListener)        
        stopAnimation()
    }
            
    func updateLocation(){
        guard let longitude = region.region?.center.longitude, let latitude = region.region?.center.latitude else{ return }
        
        if let user = user {
            fireStoreManager.updateCurrentUserLocation(user: user)
            fireStoreManager.updateUserLocation(location: CLLocation(latitude: latitude, longitude: longitude)) { result in
                switch result {
                case .success:
                    print("Update user location sucess")
                case .failure(let failure):
                    print("Update user location failed: \(failure.localizedDescription)")
                }
            }
        }
        
    }
    
    func startActivity(){
        if let groupName = selectedGroup?.groupName{
            GroupViewModel.shared.startLiveActivity(groupName: groupName, distances: memberDistance)
        }
    }
    
    func updateActivity(){
        if let groupName = selectedGroup?.groupName{
            activityTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { _ in
                self.index = ( self.index + 1 ) % 5
                GroupViewModel.shared.updateLiveActivity(groupName: groupName, distances: self.memberDistance, index: self.index)
            })
        }
    }
    
    func endLiveActivity(){
        GroupViewModel.shared.endLiveActivity()
        stopActivityAnimation()
    }
    
    func fetchGroup(){
        fireStoreManager.observeGroups { result in
            switch result {
            case .success(let success):
                self.groups = success
                print(success)
            case .failure(let failure):
                print("Fetch groups failed: \(failure.localizedDescription)")
            }
        }
    }
    
    func createGroupNavigation(){
        createGroupMode.toggle()
    }
    
    func containFriend(_ user: User) -> Bool{
        return selectedFriends.contains{ $0.key == user.uid }
    }
    
    func selectFriend(_ user: User){
        if containFriend(user){
            selectedFriends.removeValue(forKey: user.uid)
        }else{
            selectedFriends[user.uid] = user
        }
    }
    
    func createGroup(_ user: User) {
        var friends = Array(selectedFriends.values)
        friends.append(user)
        isUploadingGroup = true
        if let selectedLocation = selectedLocation{
            fireStoreManager.createGroup(name: groupName, selectedFriends: friends, destination: selectedLocation) { result in
                switch result {
                case .success:
                    self.isUploadingGroup = false
                    self.createGroupMode = false
                    self.message = "Create group success"
                    self.selectedFriends = [:]
                    self.selectedLocation = nil
                case .failure(let failure):
                    self.isUploadingGroup = false
                    self.createGroupMode = false
                    self.message = "Create group failed"
                    print("Create destination group failed: \(failure.localizedDescription)")
                }
            }
        }
    }
    
    func fetchUserImage(){
        if let uids = selectedGroup?.uids{
            for id in uids{
                CloudinaryManager().fetchImage(publicId: id) { image in
                    DispatchQueue.main.async {
                        self.membersImage[id] = image
                    }
                }
            }
        }
    }    
    
    func getMemberImage(_ uid: String) -> Image{
        return membersImage[uid] ?? Image(systemName: "person.crop.circle.fill")
    }
    
    func calculateDistance(_ user: User) -> String {
        var distance = ""
        
        let userLocation = CLLocation(latitude: user.latitude, longitude: user.longitude)
        guard let group = selectedGroup else {
            return ""
        }
        
        // Extract destination from selectedGroup and convert it into CLLocationCoordinate2D
        guard let locationDict = group.destination["destination"],
              let latitude = locationDict["latitude"],
              let longitude = locationDict["longitude"] else {
            return ""
        }
        
        let destination = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        
        distance = String(format: "%.2f km", userLocation.distance(from: destinationLocation) / 1000)
        
        return distance
    }
    
    func finishGroup(){
        var isAllUserArrived = true        
        guard let group = selectedGroup else { return }
        
        guard let locationDict = group.destination["destination"],
              let latitude = locationDict["latitude"],
              let longitude = locationDict["longitude"] else { return }
        
        let destination = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        
        for user in group.users{
            let userLocation = CLLocation(latitude: user.latitude, longitude: user.longitude)
            if (userLocation.distance(from: destinationLocation) / 1000 ) > 0.1{
                isAllUserArrived = false
                break
            }
        }
        
        if isAllUserArrived{
            deleteGroup(group.id)
        }
    }
    
    func deleteGroup(_ id: String, completion:  ((Bool) -> Void)? = nil){
        fireStoreManager.deleteGroup(id) { result in
            switch result {
            case .success(let success):
                print("Delete group successful")
                completion?(true)
            case .failure(let failure):
                self.errorMessage = "Failed to delete group"
                completion?(false)
                print("Failed to delete group :\(failure.localizedDescription)")
            }
        }
    }
    
    func regionDistance() -> String{
        var distance = ""
        
        guard let group = selectedGroup else {
            return ""
        }
        
        guard let latitude = region.region?.center.latitude, let longitude = region.region?.center.longitude else { return ""}
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        guard let locationDict = group.destination["destination"],
              let latitude = locationDict["latitude"],
              let longitude = locationDict["longitude"] else {
            return ""
        }
        
        let destinationLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        distance = String(format: "%.2f km", userLocation.distance(from: destinationLocation) / 1000)
        
        return distance
    }
    
    func currentActiveIndex(_ member: User) -> Int {
        DispatchQueue.main.async{
            if self.memberActiveIndices[member.uid] == nil {
                self.memberActiveIndices[member.uid] = Int.random(in: 0..<7)
            }
        }
        return memberActiveIndices[member.uid] ?? 0
    }
            
    func startAnimation() {
        stopAnimation()
        memberTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            if let count = self.selectedGroup?.users.count{
                self.memberInt = (self.memberInt + 1) % count
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.time = (self.time + 1) & 7
            for memberId in self.memberActiveIndices.keys {
                self.memberActiveIndices[memberId] = ((self.memberActiveIndices[memberId] ?? 0) + 1) % 7
            }
        }
    }        
    
    func stopAnimation() {
        memberTimer?.invalidate()
        memberTimer = nil
        timer?.invalidate()
        timer = nil
    }
    
    func stopActivityAnimation(){
        activityTimer?.invalidate()
        activityTimer = nil
    }
}
