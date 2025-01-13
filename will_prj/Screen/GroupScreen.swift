//
//  GroupScreen.swift
//  will_prj
//
//  Created by 邱允聰 on 12/1/2025.
//

import SwiftUI
import MapKit

struct GroupScreen: View {
    @EnvironmentObject var frdVm: FriendListViewModel
    @EnvironmentObject var mapVm: MapViewModel
    @StateObject var vm: GroupViewModel = GroupViewModel()
    
    var body: some View {
        NavigationStack {
            if vm.createGroupMode {
                ZStack {
                    MapReader { reader in
                        Map(position: $mapVm.region) {
                            if let location = vm.selectedLocation {
                                Marker(coordinate: location) {
                                    Image(systemName: "mappin.circle.fill")
                                        .frame(width: 30, height: 30)
                                }
                            }
                        }
                        .onTapGesture(perform: { screenCoordinate in
                            vm.selectedLocation = reader.convert(screenCoordinate, from: .local)
                        })
                        .loadingBackground(vm.isUploadingGroup)
                    }
                }
                .navigationTitle("Select destination")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Next", action: {
                            vm.showAlert.toggle()
                        })
                        .foregroundStyle(vm.selectedLocation == nil ? .gray : .blue)
                        .disabled(vm.selectedLocation == nil)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        NavigationLink {
                            FriendGroupSheet()
                                .environmentObject(frdVm)
                                .environmentObject(vm)
                        } label: {
                            Text("Cancel")
                                .onTapGesture {
                                    vm.createGroupNavigation()
                                }
                        }
                    }
                }
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.groups) { group in
                            VStack{
                                Button{
                                    vm.selectedGroup = group
                                    vm.groupName = group.groupName
                                    vm.fetchUserImage()
                                    vm.isNavigateToDetail.toggle()
                                    vm.getGrpActivityInfo()
                                    vm.getRegion(mapVm.region)
                                    vm.user = mapVm.myUser
                                } label:{
                                    HStack{
                                        Text("\(group.groupName)")
                                            .font(.headline)
                                        Spacer()
                                        Label("\(group.uids.count)", systemImage: "person.2.fill")
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal)
                                }
                                Divider()
                            }
                            .padding(.vertical)
                        }
                    }
                    .padding(.top)
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        NavigationLink {
                            FriendGroupSheet()
                                .environmentObject(frdVm)
                                .environmentObject(vm)
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $vm.isNavigateToDetail, destination: {
            GroupDetail()
                .environmentObject(vm)
                .environmentObject(mapVm)                
        })
        .navigationTitle("Group")
        .toolbarTitleDisplayMode(.inline)
        .loadingBackground(vm.isUploadingGroup)
        .alert("Group name", isPresented: $vm.showAlert, actions: {
            TextField("Group name", text: $vm.groupName)
                .autocorrectionDisabled()
            Button("Cancel") { vm.showAlert.toggle() }
                .foregroundStyle(.pink)
            Button("Confirm") {
                if let user = mapVm.myUser {                    
                    vm.createGroup(user)
                }
            }
            .foregroundStyle(.blue)
        })        
    }
}


#Preview {
    GroupScreen()
}
