//
//  Task.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 13/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import Foundation

struct Task {
    
    let id: String
    let userId: String
    
    let latitude: Double?
    let longitude: Double?
    let stringLocation: String?
    
    //Status of 0 means the task is pending
    //Status of 1 means the task has been accepted
    //Status of 2 means the task has been completed
    let status: Int
    
    let isOnline: Bool
    let duration: Double
    let budget: Int
    let category: String
    let description: String
    let title: String
    let creationDate: Date
    
    var isJugglerComplete: Bool
    let isUserComplete: Bool
    var isTaskReviewed: Bool
    let mutuallyAcceptedBy: String?
    var taskAccepters: [String : Bool]?
    var jugglersAccepted: [String : Bool]?
    
    init(id: String, dictionary: [String : Any]) {
        
        self.id = id
        
        self.userId = dictionary[Constants.FirebaseDatabase.userId] as? String ?? ""
        let online = dictionary[Constants.FirebaseDatabase.isTaskOnline] as? Bool ?? true
        
        if online {
            self.isOnline = true
            self.latitude = nil
            self.longitude = nil
            self.stringLocation = nil
        } else {
            self.isOnline = false
            self.latitude = dictionary[Constants.FirebaseDatabase.latitude] as? Double ?? 41.390205
            self.longitude = dictionary[Constants.FirebaseDatabase.longitude] as? Double ?? 2.154007
            self.stringLocation = dictionary[Constants.FirebaseDatabase.stringLocation] as? String ?? ""
        }
        
        self.status = dictionary[Constants.FirebaseDatabase.taskStatus] as? Int ?? 0
        
        self.budget = dictionary[Constants.FirebaseDatabase.taskBudget] as? Int ?? 0
        self.category = dictionary[Constants.FirebaseDatabase.taskCategory] as? String ?? ""
        self.description = dictionary[Constants.FirebaseDatabase.taskDescription] as? String ?? ""
        self.title = dictionary[Constants.FirebaseDatabase.taskTitle] as? String ?? ""
        self.duration = dictionary[Constants.FirebaseDatabase.taskDuration] as? Double ?? 0.0
        
        let secondsFrom1970 = dictionary[Constants.FirebaseDatabase.creationDate] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        
        self.isJugglerComplete = dictionary[Constants.FirebaseDatabase.isJugglerComplete] as? Bool ?? false
        self.isUserComplete = dictionary[Constants.FirebaseDatabase.isUserComplete] as? Bool ?? false
        self.isTaskReviewed = dictionary[Constants.FirebaseDatabase.isTaskReviewed] as? Bool ?? false
        self.mutuallyAcceptedBy = dictionary[Constants.FirebaseDatabase.mutuallyAcceptedBy] as? String
        
        self.taskAccepters = dictionary[Constants.FirebaseDatabase.taskAccepters] as? [String : Bool]
        self.jugglersAccepted = dictionary[Constants.FirebaseDatabase.jugglersAccepted] as? [String : Bool]
    }
}
