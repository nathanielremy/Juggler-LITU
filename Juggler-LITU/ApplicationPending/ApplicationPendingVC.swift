//
//  ApplicationPendingVC.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 11/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

// Only present this view controller (ApplicationPendingVC) when juggler user has
// an account but has not yet been accepted.
class ApplicationPendingVC: UIViewController {
    
    //MARK: Stored properties
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.mainBlue()
        label.text = "Your Application is Being Reviewed"
        
        return label
    }()
    
    lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: "• ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.darkText])
        attributedText.append(NSAttributedString(string: "Check your Emails Regularly", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()]))
        attributedText.append(NSAttributedString(string: ". ", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        attributedText.append(NSAttributedString(string: "We will send you the details regarding your in-person interview as soon as possible.", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        
        label.attributedText = attributedText
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(handleLogOut))
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check to make sure if juggler is accepted.
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
    
    fileprivate func setupViews() {
        view.addSubview(infoLabel)
        infoLabel.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: nil)
        infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        infoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: nil, left: view.leftAnchor, bottom: infoLabel.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: -50, paddingRight: -10, width: nil, height: nil)
    }
}
