//
//  GroupDetail.swift
//  will_prj
//
//  Created by 邱允聰 on 12/1/2025.
//

import SwiftUI
import MapKit

struct GroupDetail: View {
    @EnvironmentObject var vm: GroupViewModel
    @EnvironmentObject var mapVm: MapViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        if let group = vm.selectedGroup{
            VStack{
                Map(position: $mapVm.region, interactionModes: .all){
                    ForEach(group.users){member in
                        if let user = FirestoreManager().user{
                            Annotation(member.uid == user ? "You" : member.displayName ?? "Anonymous", coordinate: CLLocationCoordinate2D().location(member)) {
                                vm.getMemberImage(member.uid)
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
                    
                    if let destination = vm.groupDestination{
                        Marker("Destination", coordinate: destination)
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .toolbar(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .bottom){
                if !vm.showMap{
                    capsuleView(group.users[vm.memberInt])
                }
            }
            .overlay(alignment: .bottomTrailing){
                currentLocationButton
                    .padding(.bottom, 80)
                    .padding(.trailing, 10)
            }
            .overlay(alignment: .top, content: {
                Text("\(group.groupName)")
                    .font(.title2)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            })
            .overlay(alignment: .topLeading, content: {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                        .circleButtonStyle(.white)
                        .font(.title2)
                        .padding(.leading, 10)
                }
            })
            .overlay(alignment: .topTrailing){
                if let user = FirestoreManager().user{
                    if group.createUser == user{
                        Button{
                            vm.showDeleteAlert.toggle()
                        } label: {
                            Image(systemName: "trash.fill")
                                .circleButtonStyle(.pink)
                                .font(.title2)
                                .padding(.trailing, 10)
                        }
                    }
                }
            }
            .alert("Delete group", isPresented: $vm.showDeleteAlert, actions: {
                Button("Cancel", role: .cancel){
                    vm.showDeleteAlert.toggle()
                }
                Button("Confirm"){
                    vm.showDeleteAlert.toggle()
                    vm.deleteGroup(group.id) { result in
                        if result{
                            dismiss()
                        } else{
                            vm.showErrMessage.toggle()
                        }
                    }
                }
            }, message: {
                Text("Are you sure to delete group?")
            })
            .alert(vm.errorMessage, isPresented: $vm.showErrMessage, actions: {
                Button("Ok", role: .cancel){}
            })
            .onAppear{
                vm.observeGroup()                
            }
            .onDisappear{
                vm.stopObservingGroup()
                vm.endLiveActivity()
            }
            .sheet(isPresented: $vm.showMap) {
                groupMember(group)
            }
        }
    }
    
    var currentLocationButton: some View{
        Button{
            if let myUser = mapVm.myUser{
                mapVm.moveToRegion(myUser)
            }
        } label:{
            Image(systemName: "location.fill")
                .circleButtonStyle(.blue)
        }
    }
    
    func capsuleView(_ member: User) -> some View{
        Button {
            
        } label: {
            HStack{
                Text("\(member.displayName ?? "Annoymous")")
                animationView(member)
                Text("\(vm.calculateDistance(member))")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background{
                Capsule()
                    .fill(.black)
            }
        }
        .simultaneousGesture(LongPressGesture().onEnded({ _ in
            withAnimation {
                vm.showMap.toggle()
            }
        }))
        .padding()
    }
    
    func groupMember(_ group: GroupModel) -> some View{
        VStack{
            HStack{
                Text("Member")
                Spacer()
                Text("Distance")
            }
            .font(.headline)
            LazyVStack(spacing: 20){
                ForEach(group.users) { member in
                    HStack{
                        HStack{
                            vm.getMemberImage(member.uid)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .foregroundStyle(.gray)
                            if let user = FirestoreManager().user{
                                Text("\(member.uid == user ? "You" : member.displayName ?? "Annoymous")")
                            }
                        }
                        animationView(member)
                        Text("\(vm.calculateDistance(member))")
                    }
                }
            }
            .padding(.top)
        }
        .presentationDetents([.medium, .large])
        .padding()
    }
    
    
    func animationView(_ member: User) -> some View{
        HStack{
            ForEach(0..<7) { index in
                Image(systemName: "circle.fill")
                    .foregroundStyle(vm.currentActiveIndex(member) == index ? .yellow : .gray)
                    .font(.footnote)
                    .scaleEffect(vm.currentActiveIndex(member) == index ? 1.4 : 1.0)
                    .offset(y: vm.currentActiveIndex(member) == index ? -8 : 0)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 8), value: vm.currentActiveIndex(member))
                
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

//#Preview {
//    GroupDetail()
//}
