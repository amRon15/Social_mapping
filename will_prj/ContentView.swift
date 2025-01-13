//
//  ContentView.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import SwiftUI

struct ContentView: View {
    @State var selectedTab: Int = 0
    @StateObject var frdVm: FriendListViewModel = FriendListViewModel()    
    @StateObject var mapVm: MapViewModel = MapViewModel()
     
    var body: some View {
        NavigationStack{
            ZStack(alignment: .bottom) {
                Group{
                    switch selectedTab{
                    case 0: MapScreen()
                            .environmentObject(frdVm)
                            .environmentObject(mapVm)
                    case 1: GroupScreen()
                            .environmentObject(frdVm)
                            .environmentObject(mapVm)                            
                    case 2: ChatListScreen()
                    case 3: ProfileScreen(FirestoreManager().user ?? "")
                    default: MapScreen()
                            .environmentObject(frdVm)
                            .environmentObject(mapVm)
                    }
                }
                .frame(maxHeight: .infinity)
                tabbar
            }
        }
    }
    
    var tabbar: some View{
        ZStack{
            HStack(alignment: .center, spacing: 40){
                ForEach(TabbarItem.allCases, id: \.self) { item in
                    let selected = selectedTab == item.rawValue
                    Image(systemName: item.icon)
                        .foregroundStyle(selected ? .white : .gray)
                        .font(.title)
                        .onTapGesture {
                            withAnimation(.smooth){
                                selectedTab = item.rawValue
                            }
                        }
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical)
            .background{
                Capsule()
                    .fill(.black)
            }
        }
    }
}

#Preview {
    ContentView()
}
