//
//  Extension.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import Foundation
import SwiftUI
import MapKit

extension View{
    func loadingBackground(_ isLoadding: Bool) -> some View{
        self
            .overlay{
                if isLoadding{
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(2, anchor: .center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .background{
                            Color.gray.opacity(0.5)
                                .ignoresSafeArea()
                        }
                        .ignoresSafeArea()
                }
            }
    }
    
    func profileButtonStyle() -> some View{
        self
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 20).fill(.blue))
            .font(.title3)
            .foregroundStyle(.white)
    }
    
    func circleButtonStyle(_ color: Color) -> some View{
        self
            .font(.title2)
            .foregroundColor(color)
            .padding(15)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
    }
    
    func hideKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


extension CLLocationCoordinate2D{
    func location(_ user: User?) -> CLLocationCoordinate2D{
        return CLLocationCoordinate2D(latitude: user?.latitude ?? 0, longitude: user?.longitude ?? 0)
    }
    
    func regionToLocation(_ region: MapCameraPosition) -> CLLocationCoordinate2D{
        var location: CLLocationCoordinate2D?
        if let latitude = region.region?.center.latitude ,let longitude = region.region?.center.longitude{
            location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        return location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}

