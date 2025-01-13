//
//  MapScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//
import SwiftUI
import MapKit

struct MapScreen: View {
    @EnvironmentObject var vm: MapViewModel
    @EnvironmentObject var frdVm: FriendListViewModel
    @EnvironmentObject var mapVm: MapViewModel
    
    var body: some View {
        NavigationStack{
            ZStack{
                VStack{
                    Map(position: $vm.region, interactionModes: .all){
                        friendsLocation
                        
                        ForEach(vm.nearbyUser){ user in
                            Annotation(user.displayName ?? "Anonymous", coordinate: CLLocationCoordinate2D().location(user)) {
                                Button{
                                    vm.selectedUser = user
                                    vm.showOtherProfile = true
                                } label:{
                                    vm.getUserImage(user)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        .foregroundStyle(.gray)                                        
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        .shadow(radius: 3)
                                }
                            }
                        }
                        
                        Annotation("You", coordinate: CLLocationCoordinate2D().location(vm.myUser)){
                            vm.userImage?
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .foregroundStyle(.gray)
                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                .shadow(radius: 3)
                        }
                        
                        
                        MapCircle(center: CLLocationCoordinate2D().location(vm.myUser), radius: 500)
                            .foregroundStyle(.blue.opacity(0.3))
                            .mapOverlayLevel(level: .aboveRoads)
                        
                    }
                }
                .overlay{
                    VStack(spacing: 10){
                        friendListButton
                        currentLocationButton
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.bottom, 70)
                }
                .toolbar(.hidden)
                .frame(maxHeight: .infinity)
                .sheet(isPresented: $vm.showOtherProfile) {
                    if let user = vm.selectedUser {
                        FriendSheet(user: user, myUser: vm.myUser!)
                            .environmentObject(vm)
                    }
                }
                .sheet(isPresented: $vm.showFriendList) {
                    FriendListView()
                        .environmentObject(vm)
                }
                .onDisappear{
                    vm.stopUpdateUserLocation()
                }
                .navigationDestination(isPresented: $frdVm.navigateToChat) {
                    if let myUser = frdVm.myUser, let user = frdVm.user, let chatId = frdVm.chatId {
                        ChatScreen(user: myUser, chatUser: user, chatid: chatId)
                    }
                }
                .navigationDestination(isPresented: $frdVm.navigateToProfile) {
                    if let user = frdVm.user{
                        ProfileScreen(user.uid)
                    }
                }
            }
        }
    }
    
    var friendsLocation: some MapContent{
        ForEach(vm.friends){friend in
            Annotation(friend.displayName ?? "Friend", coordinate: CLLocationCoordinate2D().location(friend)){
                Button {
                    vm.selectedUser = friend
                    vm.showOtherProfile = true
                } label: {
                    frdVm.getFriendImage(friend)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .foregroundStyle(.gray)
                        .overlay(Circle().stroke(Color.yellow, lineWidth: 2))
                        .shadow(radius: 3)
                }
                
            }
        }
    }
    
    var friendListButton: some View {
        Button {
            vm.showFriendList.toggle()
        } label: {
            Image(systemName: "person.2.fill")
                .circleButtonStyle(.white)
                .font(.title2)
        }
    }
    
    var currentLocationButton: some View{
        Button{
            if let myUser = vm.myUser{
                vm.moveToRegion(myUser)
            }
        } label:{
            Image(systemName: "location.fill")
                .circleButtonStyle(.blue)
        }
    }
}

#Preview {
    MapScreen()
}
