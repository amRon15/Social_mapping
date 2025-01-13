//
//  GroupActivityManager.swift
//  will_prj
//
//  Created by 邱允聰 on 12/1/2025.
//
import Foundation
import ActivityKit

class GroupActivityManager{
    private var activity: Activity<GroupActivityAttributes>?
    
    var groupName: String = ""
    var distances: [String: String] = [:]
    var index: Int = 0
            
    func startLiveActivity(groupName: String, distances: [String: String]) {
        let attributes = GroupActivityAttributes(groupName: groupName)

        let content = ActivityContent(state: GroupActivityAttributes.ContentState(groupName: groupName, distances: distances, index: 0), staleDate: nil)
        do {
            activity = try Activity<GroupActivityAttributes>.request(attributes: attributes, content: content, pushType: nil)
            
            self.groupName = groupName
            self.distances = distances
            print("\(groupName): \(distances)")
        } catch {
            print("Failed to start live activity: \(error)")
        }
    }
        
    func updateLiveActivity(groupName: String, distances: [String: String], index: Int) {
        self.index = index
        self.groupName = groupName
        self.distances = distances

        guard let activity = activity else { return }
        let content = ActivityContent(state: GroupActivityAttributes.ContentState(groupName: groupName, distances: distances, index: index), staleDate: nil)
        
        Task {
            await activity.update(content)
        }
    }
    
    
    func endLiveActivity() {
        guard let activity = activity else { return }
        let content = ActivityContent(state: GroupActivityAttributes.ContentState(groupName: groupName, distances: distances, index: 0), staleDate: nil)
        
        Task {            
            await activity.end(content, dismissalPolicy: .immediate)
        }
    }    
}
