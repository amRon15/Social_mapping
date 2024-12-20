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
            Map(position: $vm.mapPosition){
                
            }
            .mapStyle(.hybrid)
            .overlay {
                HStack{
                    Button {
                        withAnimation(.smooth) {
                            vm.isSearching.toggle()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).fill(.black))
                    }
                        TextField("", text: $vm.searchText)
                            .padding(.horizontal)
                            .padding(.trailing, 20)
                            .font(.title2)
                            .padding(.vertical, 15)
                            .overlay(alignment: .trailing) {
                                if vm.isSearching{
                                    Image(systemName: "xmark")
                                        .padding(.trailing)
                                        .onTapGesture {
                                            vm.searchText = ""
                                        }
                                }
                            }
                            .frame(width: vm.isSearching ? .infinity : .zero)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(lineWidth: 2).foregroundStyle(.black))
                            .autocorrectionDisabled()
                            
                            
                }
                .padding(30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    MapScreen()
}
