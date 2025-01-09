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
    
    var body: some View {
        NavigationStack{
            ZStack(alignment: .bottom) {
                Group{
                    switch selectedTab{
                    case 0: MapScreen()
                            .environmentObject(frdVm)
                    case 1: ChatListScreen()
                    case 2: ProfileScreen(FirestoreManager().user ?? "")
                    default: MapScreen()
                            .environmentObject(frdVm)
                    }
                }
                .frame(maxHeight: .infinity)
                tabbar
            }
        }
    }
    
    var tabbar: some View{
        ZStack{
            HStack(alignment: .bottom, spacing: 70){
                ForEach(TabbarItem.allCases, id: \.self) { item in
                    let selected = selectedTab == item.rawValue
                    Image(systemName: item.icon)
                        .foregroundStyle(selected ? .white : .gray)
                        .font(.title)
                        .background{
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.black)
                                .frame(width: selected ? 80 : 70, height: selected ? 80 : 70)
                        }
                        .onTapGesture {
                            withAnimation(.smooth){
                                selectedTab = item.rawValue
                            }
                        }
                }
            }
        }
        .padding(.bottom, 30)
    }
}

#Preview {
    ContentView()
}
