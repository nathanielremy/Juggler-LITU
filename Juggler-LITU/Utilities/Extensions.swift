//
//  Extensions.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 10/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import Foundation
import UIKit
import Firebase

// Caches
var jugglerCache = [String : Juggler]()
var userCache = [String : User]()

//MARK: Firebase Auth
extension Auth {
    static func loginUser(withEmail email: String, passcode: String, completion: @escaping (User?, String?) -> Void) {
        
        Auth.auth().signIn(withEmail: email, password: passcode) { (usr, err) in
            if let error = err {
                completion(nil, error.localizedDescription); return
            }
            
            guard let firebaseUser = usr else {
                completion(nil, "No firebaseUser returned in closure."); return
            }
            
            Database.fetchUserFromUserID(userID: firebaseUser.uid, completion: { (usr) in
                guard let user = usr else {
                    completion(nil, "No firebaseUser returned in closure."); return
                }
                
                completion(user, nil); return
            })
        }
    }
}

//MARK: Firebase Database
extension Database {
    static func fetchUserFromUserID(userID: String, completion: @escaping (User?) -> Void) {
        
        // Check if we have already cached the user
        if let user = userCache[userID] {
            completion(user)
            return
        }
        Database.database().reference().child(Constants.FirebaseDatabase.usersRef).child(userID).observeSingleEvent(of: .value, with: { (dataSnapshot) in

            guard let userDictionary = dataSnapshot.value as? [String : Any] else {
                completion(nil)
                print("DataSnapshot dictionary not castable to [String:Any]"); return
            }

            let user = User(uid: userID, dictionary: userDictionary)
            
            userCache[user.uid] = user
            
            completion(user)

        }) { (error) in
            print("Failed to fetch dataSnapshot of currentUser", error)
            completion(nil)
        }
    }
    
    static func fetchJuggler(jugglerID: String, completion: @escaping (Juggler?) -> Void) {
        
        // Check if we have already catched the juggler
        if let juggler = jugglerCache[jugglerID] {
            completion(juggler)
            return
        }
        Database.database().reference().child(Constants.FirebaseDatabase.jugglersRef).child(jugglerID).observeSingleEvent(of: .value, with: { (dataSnapshot) in
            
            guard let userDictionary = dataSnapshot.value as? [String : Any] else {
                completion(nil)
                print("DataSnapshot dictionary not castable to [String:Any]"); return
            }
            
            let juggler = Juggler(uid: jugglerID, dictionary: userDictionary)
            
            jugglerCache[juggler.uid] = juggler
            
            completion(juggler)
            
        }) { (error) in
            print("Failed to fetch dataSnapshot of currentUser", error)
            completion(nil)
        }
    }
    
    // Helper method that verifies if the Juggler user has been accepted.
    static func isJugglerAccepted(userId: String, completion: @escaping (Juggler?) -> Void) {
        
        Database.fetchJuggler(jugglerID: userId) { (jglr) in
            if let juggler = jglr {
                if juggler.accepted == 0 {
                    completion(nil)
                } else {
                    completion(juggler)
                }
            } else {
                completion(nil)
            }
        }
    }
}

//MARK: UIView
extension UIView {
    
    static func okayAlert(title: String, message: String) -> UIAlertController {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .cancel , handler: nil)
        alertController.addAction(okAction)
        
        return alertController
    }
    
    static func noResultsView(withText text: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .white
        
        let label = UILabel()
        label.text = text
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        
        return containerView
    }
    
    static func ratingImage(fromRating rating: Double) -> UIImage {
        if rating > 0.4 && rating < 1.5 {
            return #imageLiteral(resourceName: "oneStarRating")
        } else if rating > 1.4 && rating < 2.5 {
            return #imageLiteral(resourceName: "twoStarRating")
        } else if rating > 2.4 && rating < 3.5 {
            return #imageLiteral(resourceName: "threeStarRating")
        } else if rating > 3.4 && rating < 4.5 {
            return #imageLiteral(resourceName: "fourStarRating")
        } else if rating > 4.4 {
            return #imageLiteral(resourceName: "fiveStarRating")
        } else {
            return #imageLiteral(resourceName: "zeroStarRating")
        }
    }
    
    func anchor(top: NSLayoutYAxisAnchor?, left: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, right: NSLayoutXAxisAnchor?, paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight: CGFloat, width: CGFloat?, height: CGFloat?) {
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            self.topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let bottom = bottom {
            self.bottomAnchor.constraint(equalTo: bottom, constant: paddingBottom).isActive = true
        }
        
        if let right = right {
            self.rightAnchor.constraint(equalTo: right, constant: paddingRight).isActive = true
        }
        
        if let width = width {
            self.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if let height = height {
            self.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
}

//MARK: UIColor
extension UIColor {
    
    static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
    }
    
    static func mainBlue() -> UIColor {
        return rgb(92, 153, 243)
    }
    
    static func chatBubbleGray() -> UIColor {
        return rgb(240, 240, 240)
    }
}

//MARK: Date
extension Date {
    
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        let month = 4 * week
        
        let quotient: Int
        let unit: String
        if secondsAgo < minute {
            quotient = secondsAgo
            unit = "second"
        } else if secondsAgo < hour {
            quotient = secondsAgo / minute
            unit = "min"
        } else if secondsAgo < day {
            quotient = secondsAgo / hour
            unit = "hour"
        } else if secondsAgo < week {
            quotient = secondsAgo / day
            unit = "day"
        } else if secondsAgo < month {
            quotient = secondsAgo / week
            unit = "week"
        } else {
            quotient = secondsAgo / month
            unit = "month"
        }
        
        return "\(quotient) \(unit)\(quotient == 1 ? "" : "s") ago"
    }
}
