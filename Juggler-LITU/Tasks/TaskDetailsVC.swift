//
//  TaskDetailsVC.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 13/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class TaskDetailsVC: UIViewController {
    
    //MARK: Stored properties
    var user: User?
    var task: Task? {
        didSet {
            guard let task = task else {
                self.navigationController?.popViewController(animated: true)
                return
            }
            
            fetchUser(uid: task.userId)
            self.titleLabel.text = task.title
            let budgetText: NSMutableAttributedString = self.makeAttributedText(withTitle: "Budget (eur):  ", description: "")
                budgetText.append(NSAttributedString(string: String(task.budget), attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainAmarillo()]))
            self.budgetLabel.attributedText = budgetText
            self.durationLabel.attributedText = self.makeAttributedText(withTitle: "Estimated Duration (hours): ", description: String(task.duration))
            self.categoryLabel.attributedText = self.makeAttributedText(withTitle: "Category:  ", description: task.category)
            self.descriptionTextView.text = task.description
            
            if task.isOnline {
                self.locationLabel.attributedText = self.makeAttributedText(withTitle: "Location: ", description: "Online/Phone")
            } else {
                guard let locationString = task.stringLocation else {
                    self.locationLabel.attributedText = self.makeAttributedText(withTitle: "Location: ", description: "Online/Phone")
                    return
                }
                self.viewMapButton.setTitle("View map", for: .normal)
                self.locationLabel.attributedText = self.makeAttributedText(withTitle: "Location: ", description: locationString)
            }
        }
    }
    
    fileprivate func makeAttributedText(withTitle title: String, description: String) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString(string: title + " ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()])
        attributedText.append(NSAttributedString(string: description, attributes: [.font : UIFont.systemFont(ofSize: 14), .foregroundColor : UIColor.darkText]))
        
        return attributedText
    }
    
    fileprivate func fetchUser(uid: String) {
        Database.fetchUserFromUserID(userID: uid) { (user) in
            if let user = user {
                self.user = user
                DispatchQueue.main.async {
                    self.profileImageView.loadImage(from: user.profileImageURLString)
                    self.fullNameLabel.text = user.firstName + " " + user.lastName
                }
            }
        }
    }
    
    //MARK: Views
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.bounces = true
        sv.backgroundColor = .white
        
        return sv
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.mainBlue()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    lazy var profileImageView: CustomImageView = {
        let image = CustomImageView()
        image.backgroundColor = .lightGray
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.layer.borderColor = UIColor.mainBlue().cgColor
        image.layer.borderWidth = 1.5
        image.isUserInteractionEnabled = true
        image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleProfileImageView)))
        
        return image
    }()
    
    @objc fileprivate func handleProfileImageView() {
        if let user = self.user {
            
            let userProfileVC = UserProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
            userProfileVC.user = user
            
            navigationController?.pushViewController(userProfileVC, animated: true)
            
        } else {
            let alert = UIView.okayAlert(title: "Cannot Load User", message: "We are currently unable to load this user's profile. Please try again.")
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    let fullNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .darkText
        
        return label
    }()
    
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.mainBlue()
        button.setTitle("Message", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleSendMessageButton), for: .touchUpInside)
        
        return button
    }()
    
    @objc fileprivate func handleSendMessageButton() {
        if let task = self.task, let user = self.user {
            if user.uid == Auth.auth().currentUser?.uid {
                
                let alert = UIView.okayAlert(title: "Cannot Message User", message: "Sorry you are unable to send messages to yourself.")
                self.present(alert, animated: true, completion: nil)
                
                return
            } else {
                let chatLogVC = ChatLogVC(collectionViewLayout: UICollectionViewFlowLayout())
                
                chatLogVC.shouldShowCancel = true
                chatLogVC.taskId = task.id
                chatLogVC.taskOwnerId = task.userId
                chatLogVC.data = (user, task)
                
                let chatLogNavController = UINavigationController(rootViewController: chatLogVC)
                self.present(chatLogNavController, animated: true, completion: nil)
            }
        }
    }
    
    let budgetLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        
        let topSeperatorView = UIView()
        topSeperatorView.backgroundColor = .lightGray
        
        label.addSubview(topSeperatorView)
        topSeperatorView.anchor(top: label.topAnchor, left: label.leftAnchor, bottom: nil, right: label.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)
        
        return label
    }()
    
    let durationLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        
        let topSeperatorView = UIView()
        topSeperatorView.backgroundColor = .lightGray
        
        label.addSubview(topSeperatorView)
        topSeperatorView.anchor(top: label.topAnchor, left: label.leftAnchor, bottom: nil, right: label.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)
        
        return label
    }()
    
    let categoryLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        
        let topSeperatorView = UIView()
        topSeperatorView.backgroundColor = .lightGray
        
        label.addSubview(topSeperatorView)
        topSeperatorView.anchor(top: label.topAnchor, left: label.leftAnchor, bottom: nil, right: label.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)
        
        return label
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        
        return label
    }()
    
    lazy var viewMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.mainBlue()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.addTarget(self, action: #selector(handleViewMapButton), for: .touchUpInside)
        
        return button
    }()
    
    @objc fileprivate func handleViewMapButton() {
        
        guard let task = self.task, let longitude = task.longitude, let latitude = task.latitude else {
            let alert = UIView.okayAlert(title: "Unable to load map", message: "Please contact the task owner for more details.")
            self.present(alert, animated: true, completion: nil)
            return
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        let mapView = TaskLocationMapViewVC()
        mapView.coordinnate = coordinate
        mapView.addressString = task.stringLocation
        
        navigationController?.pushViewController(mapView, animated: true)
    }
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Description:"
        label.textAlignment = .left
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = UIColor.mainBlue()
        
        return label
    }()
    
    let descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.layer.borderWidth = 0.5
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.isUserInteractionEnabled = false
        
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupViews()
    }
    
    fileprivate func setupViews() {
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: nil)
        scrollView.contentSize = CGSize(width: view.frame.width, height: 860)

        scrollView.addSubview(titleLabel)
        titleLabel.anchor(top: scrollView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: 70)

        scrollView.addSubview(profileImageView)
        profileImageView.anchor(top: titleLabel.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
        profileImageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        profileImageView.layer.cornerRadius = 100 / 2
        
        scrollView.addSubview(fullNameLabel)
        fullNameLabel.anchor(top: profileImageView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: 50)

        scrollView.addSubview(sendMessageButton)
        sendMessageButton.anchor(top: fullNameLabel.bottomAnchor, left: nil , bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 125, height: 35)
        sendMessageButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        sendMessageButton.layer.cornerRadius = 16

        setupStackView()
    }
    
    fileprivate func setupStackView() {
        let stackView = UIStackView(arrangedSubviews: [budgetLabel, durationLabel, categoryLabel])
        scrollView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0

        stackView.anchor(top: sendMessageButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: 180)

        scrollView.addSubview(viewMapButton)
        viewMapButton.anchor(top: stackView.bottomAnchor, left: nil, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 60, height: 95)

        scrollView.addSubview(locationLabel)
        locationLabel.anchor(top: stackView.bottomAnchor, left: stackView.leftAnchor, bottom: nil, right: viewMapButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: -5, width: nil, height: 95)

        let locationSeperatorView = UIView()
        locationSeperatorView.backgroundColor = .lightGray

        scrollView.addSubview(locationSeperatorView)
        locationSeperatorView.anchor(top: locationLabel.topAnchor, left: stackView.leftAnchor, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)

        scrollView.addSubview(descriptionLabel)
        descriptionLabel.anchor(top: locationLabel.bottomAnchor, left: stackView.leftAnchor, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 50)

        let descriptionSeperatorView = UIView()
        descriptionSeperatorView.backgroundColor = .lightGray

        scrollView.addSubview(descriptionSeperatorView)
        descriptionSeperatorView.anchor(top: descriptionLabel.topAnchor, left: stackView.leftAnchor, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)

        scrollView.addSubview(descriptionTextView)
        descriptionTextView.anchor(top: descriptionLabel.bottomAnchor, left: stackView.leftAnchor, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 200)
    }
}
