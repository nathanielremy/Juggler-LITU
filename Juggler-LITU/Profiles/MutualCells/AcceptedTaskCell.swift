//
//  AcceptedTaskCell.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 17/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

protocol AcceptedTaskCellJugglerDelegate {
    func handleCompleteTaskButton(forTask task: Task?, userId: String?, acceptedTaskArrayIndex: Int?, completion: @escaping (Bool) -> Void )
    func showUserProfile(withUserId userId: String?)
}

class AcceptedTaskCell: UICollectionViewCell {
    
    //MARK: Stored properties
    var delegate: AcceptedTaskCellJugglerDelegate?
    var isCurrentUserJuggler: Bool? {
        didSet {
            if let bool = isCurrentUserJuggler {
                if bool {
                    self.setupCompleteTaskButton()
                }
            }
        }
    }
    
    var task: Task? {
        didSet {
            guard let task = task else { return }
            self.titleLabel.text = task.title
            self.specifyBudgetLabelText(task.budget)
            self.timeAgoLabel.text = task.creationDate.timeAgoDisplay()
            
            if task.isOnline {
                self.specifyLocationLabelText("Online/Phone")
            } else {
                if let location = task.stringLocation {
                    self.specifyLocationLabelText(location)
                } else {
                    self.specifyLocationLabelText("Invalid Location")
                }
            }
            
            if task.isJugglerComplete {
                setTaskToJugglerComplete()
            } else {
                setTaskToJugglerUnComplete()
            }
        }
    }
    
    var userId: String? {
        didSet {
            guard let id = userId else { return }
            Database.fetchUserFromUserID(userID: id) { (usr) in
                if let user = usr {
                    DispatchQueue.main.async {
                        self.profileImageView.loadImage(from: user.profileImageURLString)
                    }
                    self.firstNameLabel.text = user.firstName
                }
            }
        }
    }

    var jugglerId: String? {
        didSet {
            guard let id = jugglerId else { return }
            Database.fetchJuggler(userID: id) { (jglr) in
                if let juggler = jglr {
                    DispatchQueue.main.async {
                        self.profileImageView.loadImage(from: juggler.profileImageURLString)
                    }
                    self.firstNameLabel.text = juggler.firstName
                }
            }
        }
    }
    
    //MARK: Index is used to later have a reference to the task inside the JugglerProfileVC.acceptedTasks array
    var acceptedTaskArrayIndex: Int?
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .lightGray
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        
        return iv
    }()
    
    @objc fileprivate func handleProfileImageView() {
        delegate?.showUserProfile(withUserId: self.userId)
    }
    
    let firstNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = .darkText
        label.numberOfLines = 0
        
        return label
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor.mainBlue()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        
        return label
    }()
    
    let budgetLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        
        return label
    }()
    
    fileprivate func specifyBudgetLabelText(_ budget: Int) {
        let attributedText = NSMutableAttributedString(string: "Budget (Euros): ", attributes: [.font : UIFont.systemFont(ofSize: 14), .foregroundColor : UIColor.gray])
        attributedText.append(NSAttributedString(string: "\(budget)", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()]))
        
        budgetLabel.attributedText = attributedText
    }
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        
        return label
    }()
    
    fileprivate func specifyLocationLabelText(_ location: String) {
        let attributedText = NSMutableAttributedString(string: "Location: ", attributes: [.font : UIFont.systemFont(ofSize: 14), .foregroundColor : UIColor.gray])
        attributedText.append(NSAttributedString(string: location, attributes: [.font : UIFont.systemFont(ofSize: 14), .foregroundColor : UIColor.gray]))
        
        locationLabel.attributedText = attributedText
    }
    
    let timeAgoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        
        return label
    }()
    
    lazy var completeTaskButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleCompleteTaskButton), for: .touchUpInside)

        return button
    }()
    
    @objc fileprivate func handleCompleteTaskButton() {
        self.completeTaskButton.isEnabled = false
        self.completeTaskButton.setTitle("Loading...", for: .normal)

        delegate?.handleCompleteTaskButton(forTask: self.task, userId: self.userId, acceptedTaskArrayIndex: acceptedTaskArrayIndex, completion: { (success) in
            if !success {
                self.setTaskToJugglerUnComplete()
            } else {
                self.setTaskToJugglerComplete()
            }
            self.completeTaskButton.isEnabled = true
        })
    }
    
    fileprivate func setTaskToJugglerComplete() {
        self.completeTaskButton.setTitleColor(UIColor.mainAmarillo(), for: .normal)
        self.completeTaskButton.setTitle("Completed", for: .normal)
    }

    fileprivate func setTaskToJugglerUnComplete() {
        self.completeTaskButton.setTitleColor(UIColor.mainBlue(), for: .normal)
        self.completeTaskButton.setTitle("Complete Task", for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        setupViews()
    }
    
    fileprivate func setupViews() {
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 60, height: 60)
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 60 / 2
        
        //Add button over profileImageView to view profile
        let button = UIButton()
        button.backgroundColor = nil
        addSubview(button)
        button.anchor(top: profileImageView.topAnchor, left: profileImageView.leftAnchor, bottom: profileImageView.bottomAnchor, right: profileImageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 60, height: 60)
        button.layer.cornerRadius = 60/2
        button.addTarget(self, action: #selector(handleProfileImageView), for: .touchUpInside)
        
        addSubview(firstNameLabel)
        firstNameLabel.anchor(top: profileImageView.bottomAnchor, left: self.leftAnchor, bottom: self.bottomAnchor, right: profileImageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: nil, height: nil)
        firstNameLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        
        addSubview(titleLabel)
        titleLabel.anchor(top: self.topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: self.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: -8, width: nil, height: 25)
        
        addSubview(budgetLabel)
        budgetLabel.anchor(top: titleLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: self.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: -8, width: nil, height: 20)
        
        addSubview(locationLabel)
        locationLabel.anchor(top: budgetLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: self.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: -8, width: nil, height: 20)
        
        addSubview(timeAgoLabel)
        timeAgoLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: self.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: -8, paddingRight: -8, width: nil, height: nil)
        
        let bottomSeperatorView = UIView()
        bottomSeperatorView.backgroundColor = UIColor.mainBlue()
        
        addSubview(bottomSeperatorView)
        bottomSeperatorView.anchor(top: nil, left: self.leftAnchor, bottom: self.bottomAnchor, right: self.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)
    }
    
    fileprivate func setupCompleteTaskButton() {
        // Only if current user is a juggler
        if self.jugglerId == nil {
            addSubview(self.completeTaskButton)
            completeTaskButton.anchor(top: nil, left: nil, bottom: self.bottomAnchor, right: self.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -4, paddingRight: -8, width: 112, height: 21)
            completeTaskButton.layer.cornerRadius = 21 / 2
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
