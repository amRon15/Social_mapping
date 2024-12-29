//
//  Extension.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import Foundation
import SwiftUI

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
}
