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
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let profileImageURLString = "profileImageURLString"
        static let isJuggler = "isJuggler"
        static let hasAppliedForJuggler = "hasAppliedForJuggler"
        
        static let userAccepted = "userAccepted"
        
        static let applicationsRef = "applications"
        
        static let acceptedTasks = "acceptedTasks"
        static let completedTasks = "completedTasks"
        
        static let tasksRef = "tasks"
        static let taskStatus = "taskStatus"
        static let taskReviewed = "taskReviewed"
        static let taskCategory = "taskCategory"
        static let taskTitle = "taskTitle"
        static let taskDescription = "taskDescription"
        static let taskDuration = "taskDuration"
        static let taskBudget = "taskBudget"
        static let isTaskOnline = "isTaskOnline"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let stringLocation = "stringLocation"
        static let creationDate = "creationDate"
        static let isJugglerComplete = "isJugglerComplete"
        static let isUserComplete = "isUserComplete"
        static let mutuallyAcceptedBy = "mutuallyAcceptedBy"
        static let taskAccepters = "taskAccepters"
        static let jugglersAccepted = "jugglersAccepted"
        
        static let jugglerTasksRef = "jugglerTasks"
        static let messagesRef = "messages"
        static let userMessagesRef = "user-messages"
        static let text = "text"
        static let fromId = "fromId"
        static let toId = "toId"
        static let taskId = "taskId"
        static let timeStamp = "timeStamp"
        static let taskOwnerId = "taskOwnerId"
        
        static let reviewsRef = "reviews"
        static let rating = "rating"
        static let reviewDescription = "reviewDescription"
    }
    
    struct CollectionViewCellIds {
        static let jugglerProfileHeaderCell = "jugglerProfileHeaderCell"
        static let userProfileHeaderCell = "userProfileHeaderCell"
        static let ChooseTaskCategoryHeaderCell = "chooseTaskCategoryHeaderCell"
        static let taskCell = "taskCell"
        static let chatMessageCellId = "chatMessageCellId"
        static let acceptedTaskCell = "acceptedTaskCell"
        static let completedTaskCell = "completedTaskCell"
        static let reviewCell = "reviewCell"
        static let pendingTaskCell = "pendingTaskCell"
    }
    
    struct TableViewCellIds {
        static let messageTableViewCell = "messageTableViewCell"
    }
    
    struct TaskCategories {
        static let all = "All"
        static let cleaning = "Cleaning"
        static let delivery = "Delivery"
        static let moving = "Moving"
        static let computerIT = "Computer/IT"
        static let photoVideo = "Photo/Video"
        static let handyMan = "Handyman"
        static let assembly = "Assembly"
        static let anything = "Anything"

        static func categoryArray() -> [String] {
            return [self.cleaning, self.handyMan, self.computerIT, self.photoVideo, self.assembly, self.delivery, self.moving, self.anything]
        }
    }
    
    struct ErrorDescriptions {
        static let invalidPassword = "The password is invalid or the user does not have a password."
        static let invalidEmailAddress = "There is no user record corresponding to this identifier. The user may have been deleted."
        static let networkError = "Network error (such as timeout, interrupted connection or unreachable host) has occurred."
        static let unavailableEmail = "The email address is already in use by another account."
    }
}
