//
//  Constants.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 10/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import Foundation

class Constants {
    
    struct FirebaseStorage {
        static let profileImages = "profile_images"
    }
    
    struct FirebaseDatabase {
        static let usersRef = "users"
        static let userId = "userId"
        static let emailAddress = "emailAddress"
        static let fullName = "fullName"
        static let profileImageURLString = "profileImageURLString"
        
        static let jugglersRef = "jugglers"
        static let userAccepted = "userAccepted"
        
        static let applicationsRef = "applications"
        
        static let tasksRef = "tasks"
        static let taskStatus = "taskStatus"
        static let taskReviewed = "taskReviewed"
        static let taskCategory = "taskCategory"
        static let taskTitle = "taskTitle"
        static let taskDescription = "taskDescription"
        static let taskBudget = "taskBudget"
        static let isTaskOnline = "isTaskOnline"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let stringLocation = "stringLocation"
        static let creationDate = "creationDate"
    }
    
    struct CollectionViewCellIds {
        static let jugglerProfileHeaderCell = "jugglerProfileHeaderCell"
    }
    
    struct ErrorDescriptions {
        static let invalidPassword = "The password is invalid or the user does not have a password."
        static let invalidEmailAddress = "There is no user record corresponding to this identifier. The user may have been deleted."
        static let networkError = "Network error (such as timeout, interrupted connection or unreachable host) has occurred."
        static let unavailableEmail = "The email address is already in use by another account."
    }
}
