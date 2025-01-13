//
//  GroupActivityLiveActivity.swift
//  GroupActivity
//
//  Created by 邱允聰 on 11/1/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GroupActivityAttributes: ActivityAttributes {
    public typealias GroupActivityStatus = ContentState
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var groupName: String
        var distances: [String: String]
        var index: Int
    }
    
    // Fixed non-changing properties about your activity go here!
    var groupName: String
}

struct GroupActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GroupActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text(context.attributes.groupName)
                    .font(.headline)
                HStack{
                    VStack{
                        Text("Member")
                            .font(.headline)
                        ForEach(context.state.distances.keys.sorted(), id: \.self) { user in
                            Text(user)
                        }
                    }
                    HStack{
                        ForEach(0..<5) { index in
                            Image(systemName: index == 2 ? "figure.walk" : "circle.fill")
                                .foregroundStyle(context.state.index == index ? .yellow : .gray)
                                .font(index == 2 ? .headline : .footnote)
                                .scaleEffect(context.state.index == index ? 1.2 : 1.0)
                                .offset(y: context.state.index == index ? -8 : 0)
                                .animation(.interpolatingSpring(stiffness: 170, damping: 8), value: context.state.index)
                        }
                    }
                    .foregroundStyle(.gray)
                    .frame(maxHeight: .infinity, alignment: .center)
                    VStack{
                        Text("Distance")
                            .font(.headline)
                        ForEach(context.state.distances.keys.sorted(), id: \.self) { user in
                            Text("\(context.state.distances[user] ?? "0km")")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding()
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.black)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    VStack(spacing: 5) {
                        Text("Member")
                            .font(.caption)
                        
                        VStack{
                            ForEach(context.state.distances.keys.sorted().prefix(3), id: \.self) { user in
                                Text(user)
                            }
                            
                            if context.state.distances.keys.count > 3 {
                                Image(systemName: "ellipsis")
                                    .rotationEffect(.degrees(90))
                                    .foregroundStyle(.gray)
                                    .padding(.top, 10)
                            }
                        }
                        .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                DynamicIslandExpandedRegion(.center){
                    HStack{
                        ForEach(0..<5) { index in
                            Image(systemName: index == 2 ? "figure.walk" : "circle.fill")
                                .foregroundStyle(context.state.index == index ? .yellow : .gray)
                                .font(index == 2 ? .headline : .footnote)
                                .scaleEffect(context.state.index == index ? 1.2 : 1.0)
                                .offset(y: context.state.index == index ? -8 : 0)
                                .animation(.interpolatingSpring(stiffness: 170, damping: 8), value: context.state.index)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.top, 10)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 5) {
                        Text("Distance")
                            .font(.caption)
                        
                        VStack{
                            ForEach(context.state.distances.keys.sorted().prefix(3), id: \.self) { user in
                                Text("\(context.state.distances[user] ?? "0km")")
                            }
                            
                            if context.state.distances.keys.count > 3 {
                                Image(systemName: "ellipsis")
                                    .rotationEffect(.degrees(90))
                                    .foregroundStyle(.gray)
                                    .padding(.top, 10)
                            }
                        }
                        .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.groupName)")
                        .font(.headline)
                        .frame(maxHeight: .infinity, alignment: .center)
                }
            } compactLeading: {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.yellow)
            } compactTrailing: {
                Image(systemName: "ellipsis")
            } minimal: {
                Image(systemName: "mappin.and.ellipse")
            }
            .keylineTint(Color.black)
            
        }
    }
}
//
//extension GroupActivityAttributes {
//    fileprivate static var preview: GroupActivityAttributes {
//        GroupActivityAttributes(groupName: "World")
//    }
//}
//
//#Preview("Expanded", as: .content, using: GroupActivityAttributes.preview) {
//    GroupActivityLiveActivity()
//} contentStates: {
//    GroupActivityAttributes.ContentState.init(groupName: "Hiking Group", distances: [
//        "Alice": "12km",
//        "Bob": "8.55km",
//        "Charlie": "21.0km",
//    ])
//}
