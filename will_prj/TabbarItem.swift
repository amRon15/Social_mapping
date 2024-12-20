//
//  TabbarItem.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import Foundation

enum TabbarItem: Int, CaseIterable{
    case home = 0
    case chat
    case profile
    
    var icon: String{
        switch self {
        case .home:
            return "house"
        case .chat:
            return "ellipsis.bubble"
        case .profile:
            return "person.crop.circle"
        }
    }
}
