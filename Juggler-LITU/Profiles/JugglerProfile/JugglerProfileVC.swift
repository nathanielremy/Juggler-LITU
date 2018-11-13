//
//  JugglerProfileVC.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 11/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

class JugglerProfileVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .red
        
        //FIXME: Move the below call to fetchJuggler function.
        setupSettingsBarButton()
        
        if MainTabBarController.isJugglerAccepted != true {
            hasJugglerBeenAccepted()
        }
    }
    
    fileprivate func setupSettingsBarButton() {
        let settingsBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(handleSettingsBarButton))
        settingsBarButton.tintColor = UIColor.mainBlue()
        navigationItem.rightBarButtonItem = settingsBarButton
    }
    
    @objc fileprivate func handleSettingsBarButton() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
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
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func display(alert: UIAlertController) {
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // If the user is not signed in, this function will log out the user
    // If juggler is accepted then this function supplies us with a juggler object
    // IF juggler is not accepted then this function presents
    fileprivate func hasJugglerBeenAccepted() {
        guard let userId = Auth.auth().currentUser?.uid else {
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
        
        Database.isJugglerAccepted(userId: userId) { (jglr) in
            if let juggler = jglr {
                
                MainTabBarController.isJugglerAccepted = true
                print("JugglerProfileVC, JUGGLER: \(juggler)")
                
            } else {
                
                MainTabBarController.isJugglerAccepted = false
                self.present(UINavigationController(rootViewController: ApplicationPendingVC()), animated: true, completion: nil)
                
            }
        }
    }
}
