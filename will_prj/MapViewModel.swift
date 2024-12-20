//
//  MapViewModel.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import Foundation
import MapKit
import _MapKit_SwiftUI

class MapViewModel: ObservableObject{
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    
    @Published var mapPosition = MapCameraPosition.automatic
}
