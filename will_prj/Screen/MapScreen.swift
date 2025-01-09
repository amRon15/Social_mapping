//
//  MapScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//
import SwiftUI
import MapKit

struct MapScreen: View {
    @StateObject var vm: MapViewModel = MapViewModel()
    @EnvironmentObject var frdVm: FriendListViewModel
    
    var body: some View {
        NavigationStack{
            ZStack{
                VStack{
                    Map{
                        Annotation(vm.myUser?.displayName ?? "My User", coordinate: CLLocationCoordinate2D().location(vm.myUser)){
                            vm.userImage?
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                        MapCircle(center: CLLocationCoordinate2D().location(vm.myUser), radius: 500)
                            .foregroundStyle(.blue.opacity(0.3))
                            .mapOverlayLevel(level: .aboveRoads)
                        
                        ForEach(vm.nearbyUser) { user in
                            if user.uid != vm.myUser?.uid {
                                Annotation(user.displayName ?? "Anonymous", coordinate: CLLocationCoordinate2D().location(user)) {
                                    Button {
                                        vm.selectedUser = user
                                        vm.showOtherProfile = true
                                    } label: {
                                        if let userImage = vm.nearbyUserImage[user.uid] {
                                            userImage
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                                .shadow(radius: 3)
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.gray)
                                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                                .shadow(radius: 3)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                VStack {
                    HStack {
                        Spacer()
                        friendListButton
                            .padding(.top, 30)
                            .padding(.horizontal)
                    }
                    Spacer()
                }
                .toolbar(.hidden)
                .frame(maxHeight: .infinity)
                .sheet(isPresented: $vm.showOtherProfile) {
                    if let user = vm.selectedUser {
                        FriendSheet(user: user, myUser: vm.myUser!)
                    }
                }
                .sheet(isPresented: $vm.showFriendList) {
                    FriendListView()
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
    
    var friendListButton: some View {
        Button {
            vm.showFriendList.toggle()
        } label: {
            Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}

#Preview {
    MapScreen()
}
