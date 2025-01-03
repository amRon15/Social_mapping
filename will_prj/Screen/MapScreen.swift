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
    
    var body: some View {
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
                
                ForEach(vm.nearbyUser){user in
                    if user.uid != vm.myUser?.uid{
                        Annotation(user.displayName ?? "Annoymous", coordinate: CLLocationCoordinate2D().location(user)) {
                            NavigationLink {
                                ChatScreen(user: vm.myUser!, chatUser: user, chatid: nil)
                            } label: {
                                vm.nearbyUserImage[user.uid]?
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            //                .mapStyle(.(elevation: .realistic))
            //                .overlay {
            //                    HStack{
            //                        Button {
            //                            withAnimation(.smooth) {
            //                                //                            vm.isSearching.toggle()
            //                            }
            //                        } label: {
            //                            Image(systemName: "magnifyingglass")
            //                                .font(.title)
            //                                .foregroundStyle(.white)
            //                                .padding()
            //                                .background(RoundedRectangle(cornerRadius: 20).fill(.black))
            //                        }
            //                    }
            //                    .padding(30)
            //                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            //                }
            
        }
        .toolbar(.hidden)
        .frame(maxHeight: .infinity)
        .onDisappear{
            vm.stopUpdateUserLocation()
        }
    }
    
    //    var searchBar: some View{
    //        VStack{
    //            TextField("", text: $vm.searchText)
    //                .padding(.horizontal)
    //                .padding(.trailing, 20)
    //                .font(.title2)
    //                .padding(.vertical, 15)
    //                .overlay(alignment: .trailing) {
    //                    if vm.isSearching{
    //                        Button {
    //                            vm.searchText = ""
    //                        } label: {
    //                            Image(systemName: "xmark")
    //                                .padding(.trailing)
    //                                .foregroundStyle(.gray)
    //                        }
    //
    //                    }
    //                }
    //                .frame(width: vm.isSearching ? .infinity : .zero)
    //                .background(RoundedRectangle(cornerRadius: 20).fill(.white))
    //                .overlay(RoundedRectangle(cornerRadius: 20).stroke(lineWidth: 2).foregroundStyle(.black))
    //                .autocorrectionDisabled()
    //        }
    //    }
}

#Preview {
    MapScreen()
}
