//
//  ApplicationPendingVC.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 11/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

class ApplicationPendingVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .green
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(handleLogOut))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
                if juggler.accepted == 1 {
                    MainTabBarController.isJugglerAccepted = true
                    self.dismiss(animated: true, completion: nil)
                } else {
                    MainTabBarController.isJugglerAccepted = false
                }
            } else {
                return
            }
        }
    }
    
    @objc fileprivate func handleLogOut() {
        do {
            try Auth.auth().signOut()
            
            MainTabBarController.isJugglerAccepted = false
            
            let loginVC = LoginVC()
            let signupNavController = UINavigationController(rootViewController: loginVC)
            self.present(signupNavController, animated: true, completion: nil)
            
        } catch let signOutError {
            print("Unable to sign out: \(signOutError)")
            let alert = UIView.okayAlert(title: "Unable to Log out", message: "You are unnable to log out at this moment.")
            self.display(alert: alert)
        }
    }
    
    fileprivate func display(alert: UIAlertController) {
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
