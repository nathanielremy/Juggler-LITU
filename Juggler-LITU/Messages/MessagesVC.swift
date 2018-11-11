//
//  MessagesVC.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 11/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

class MessagesVC: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Messages"
        tableView.backgroundColor = .blue
        
        if !MainTabBarController.isJugglerAccepted {
            isJugglerAccepted()
        }
    }
    
    //Verify that the user has been accepted.
    fileprivate func isJugglerAccepted() {
        guard let uId = Auth.auth().currentUser?.uid else {
            do {
                try Auth.auth().signOut()
                
                MainTabBarController.isJugglerAccepted = false
                
                let loginVC = LoginVC()
                let signupNavController = UINavigationController(rootViewController: loginVC)
                self.present(signupNavController, animated: true, completion: nil)
                
            } catch let signOutError {
                fatalError("Unable to sign out: \(signOutError)")
            }
            return
        }
        
        Database.fetchJuggler(userID: uId) { (jglr) in
            if let juggler = jglr {
                if juggler.accepted == 0 {
                    self.present(UINavigationController(rootViewController: ApplicationPendingVC()), animated: true, completion: nil)
                } else {
                    MainTabBarController.isJugglerAccepted = true
                }
            } else {
                fatalError()
            }
        }
    }
}
