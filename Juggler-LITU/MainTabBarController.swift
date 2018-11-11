//
//  MainTabBarController.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 11/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    //MARK: Stored properties
    static var viewToDismiss: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        
        if Auth.auth().currentUser == nil {
            // Show LogInVC if user is not signed in
            DispatchQueue.main.async {
                let logInVC = LoginVC()
                let navController = UINavigationController(rootViewController: logInVC)
                self.present(navController, animated: true, completion: nil)
                return
            }
        } else {
            // Set up TabBarViewControllers if user is signed in
            setupViewControllers()
        }
    }
    
    fileprivate func verifyJugglerHasBeenAccepted(forJuggler juggler: Juggler) {
        if juggler.accepted == 0 {
            let applicationPendingNavVC = UINavigationController(rootViewController: ApplicationPendingVC())
            self.present(applicationPendingNavVC, animated: true, completion: nil)
        } else {
            guard let viewToDismiss = MainTabBarController.viewToDismiss else {
                return
            }
            viewToDismiss.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate func fetchJuggler() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Database.fetchJuggler(userID: userId) { (jglr) in
            if let juggler = jglr {
                self.verifyJugglerHasBeenAccepted(forJuggler: juggler)
            } else {
                // Crash the app if no Juggler is returned from the outer function call.
                fatalError("No Juggler returned: MainTabBarController")
            }
        }
    }
    
    func setupViewControllers() {
        fetchJuggler()
        
        // Juggler profile
        let jugglerNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "profile_unselected"), selectedImage: #imageLiteral(resourceName: "profile_unselected"), rootViewController: JugglerProfileVC(collectionViewLayout: UICollectionViewFlowLayout()))

        // Messages
        let messagesNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "comment"), selectedImage: #imageLiteral(resourceName: "comment"), rootViewController: MessagesVC())

        // ViewTasks
        let viewTasksNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "home"), selectedImage: #imageLiteral(resourceName: "home"), rootViewController: ViewTasksVC(collectionViewLayout: UICollectionViewFlowLayout()))

        tabBar.tintColor = UIColor.mainBlue()
        self.viewControllers = [
            viewTasksNavController,
            messagesNavController,
            jugglerNavController
        ]
    }
    
    fileprivate func templateNavController(unselectedImage: UIImage, selectedImage: UIImage, rootViewController: UIViewController = UIViewController()) -> UINavigationController {
        let vC = rootViewController
        let navVC = UINavigationController(rootViewController: vC)
        navVC.tabBarItem.image = unselectedImage
        navVC.tabBarItem.selectedImage = selectedImage
        
        return navVC
    }
}
