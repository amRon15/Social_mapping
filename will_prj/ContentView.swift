//
//  ContentView.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import SwiftUI

struct ContentView: View {
    @State var selectedTab: Int = 0
        
    var body: some View {
//        if loginVm.isLoginSuccess{}
        ZStack(alignment: .bottom) {
            Group{
                switch selectedTab{
                case 0: MapScreen()
                case 1: ChatListScreen()
                case 2: ProfileScreen()
                default: MapScreen()
                }
            }
            .frame(maxHeight: .infinity)
            tabbar
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
