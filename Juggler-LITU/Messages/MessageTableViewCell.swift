//
//  MessageTableViewCell.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 15/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

protocol MessageTableViewCellDelegate {
    func handleViewTaskButton(forTask task: Task?)
    func handleProfileImageView(forUser user: User?)
    
    // Completion handler's parameter is a status.
    // Check updateAcceptedStatus func for the meaning
    // and values of each status
    func handleAcceptUser(forTask task: Task?, user: User?, completion: @escaping (Int) -> Void)
}

class MessageTableViewCell: UITableViewCell {
    
    //MARK: Stores properties
    var delegate: MessageTableViewCellDelegate?
    var task: Task? {
        didSet {
            if let task = task, let currentuserID = Auth.auth().currentUser?.uid, let user = self.message.1 {
                self.taskTitleLabel.text = task.title
                
                if task.status == 2 { // Is task completed
                    self.updateAcceptedStatus(forStatus: 4, userFirstName: user.firstName)
                    return
                }
                
                if let mutuallyAccepted = task.mutuallyAcceptedBy {
                    self.updateAcceptedStatus(forStatus: 3, userFirstName: user.firstName)
                    
                    if mutuallyAccepted == currentuserID {
                        self.acceptedStatusLabel.text = "You have been accepted to complete \(user.firstName)'s task!"
                    }
                    
                    return
                }
                
                // Only move forward if the task is in pending state
                guard task.status == 0 else {
                    return
                }
                
                self.updateAcceptedStatus(forStatus: 0, userFirstName: user.firstName)
                
                if task.taskAccepters?[currentuserID] != nil {
                    
                    self.updateAcceptedStatus(forStatus: 1, userFirstName: user.firstName)
                    return
                    
                } else if task.jugglersAccepted?[currentuserID] != nil {
                    
                    self.updateAcceptedStatus(forStatus: 2, userFirstName: user.firstName)
                    return
                }
            } else {
                self.taskTitleLabel.text = "Task Deleted"
                print("Task property is nil")
                return
            }
        }
    }
    
    fileprivate func updateAcceptedStatus(forStatus status: Int, userFirstName: String) {
        if status == 0 { // Accepted by nobody
            
            self.acceptedStatusLabel.text = "Want to do \(userFirstName)'s task?"
            self.acceptButton.setTitle("Accept Task", for: .normal)
            self.acceptButton.setTitleColor(.white, for: .normal)
            self.acceptButton.backgroundColor = UIColor.mainBlue()
            self.acceptButton.isEnabled = true
            
        } else if status == 1 { // Accepted only by current user
            
            self.acceptedStatusLabel.text = "Waiting for \(userFirstName) to accept you back"
            self.acceptButton.setTitle("Accepted", for: .normal)
            self.acceptButton.setTitleColor(UIColor.mainBlue(), for: .normal)
            self.acceptButton.backgroundColor = .clear
            self.acceptButton.isEnabled = false
            
        } else if status == 2 { // Accepted only by chat partner
            
            self.acceptedStatusLabel.text = "\(userFirstName) has accepted you!"
            self.acceptButton.setTitle("Accept back", for: .normal)
            self.acceptButton.setTitleColor(.white, for: .normal)
            self.acceptButton.backgroundColor = UIColor.mainBlue()
            self.acceptButton.isEnabled = true
            
        } else if status == 3 { // Mutually accepted
            
            self.acceptedStatusLabel.text = "This task is being completed by another Juggler"
            self.acceptButton.setTitle("In progress", for: .normal)
            self.acceptButton.setTitleColor(UIColor.mainBlue(), for: .normal)
            self.acceptButton.backgroundColor = .clear
            self.acceptButton.isEnabled = false
            
        } else if status == 4 { // Completed
            
            self.acceptedStatusLabel.text = "This task has been completed"
            self.acceptButton.setTitle("Completed", for: .normal)
            self.acceptButton.setTitleColor(UIColor.mainBlue(), for: .normal)
            self.acceptButton.backgroundColor = .clear
            self.acceptButton.isEnabled = false
        }
    }
    
    var message: (Message?, User?) {
        didSet {
            guard let theMessage = message.0, let user = message.1 else {
                print("No message or user"); return
            }
            
            profileImageView.loadImage(from: user.profileImageURLString)
            fetchTaskFor(userId: theMessage.taskOwnerId, taskId: theMessage.taskId)
            nameLabel.text = user.firstName + " " + user.lastName
            messageTextLabel.text = theMessage.text
            timeLabel.text = theMessage.timeStamp.timeAgoDisplay()
        }
    }
    
    fileprivate func fetchTaskFor(userId: String, taskId: String) {
        let taskRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(userId).child(taskId)
        taskRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String : Any] else {
                self.task = nil
                print("Could not convert snapshot to [String : Any]"); return
            }
            
            let task = Task(id: snapshot.key, dictionary: dictionary)
            self.task = task
            
        }) { (error) in
            print("Error fetching task: ", error); return
        }
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .lightGray
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        
        return iv
    }()
    
    @objc func handleProfileImageView() {
        guard let user = message.1 else { return }
        delegate?.handleProfileImageView(forUser: user)
    }
    
    lazy var viewTaskButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View Task", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.mainBlue()
        button.addTarget(self, action: #selector(handleViewTaskButton), for: .touchUpInside)
        
        return button
    }()
    
    @objc func handleViewTaskButton() {
        delegate?.handleViewTaskButton(forTask: self.task)
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = .darkText
        label.textAlignment = .left
        
        return label
    }()
    
    let taskTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = .left
        
        return label
    }()
    
    let messageTextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkText
        label.textAlignment = .left
        
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        
        return label
    }()
    
    let acceptedStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .darkText
        label.textAlignment = .left
        label.numberOfLines = 0
        
        return label
    }()
    
    lazy var acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.isEnabled = false
        button.addTarget(self, action: #selector(handleAcceptedButton), for: .touchUpInside)
        
        return button
    }()
    
    @objc fileprivate func handleAcceptedButton() {
        self.acceptButton.isEnabled = false
        self.acceptButton.setTitle("Loading...", for: .normal)
        
        delegate?.handleAcceptUser(forTask: self.task, user: self.message.1, completion: { (status) in
            self.updateAcceptedStatus(forStatus: status, userFirstName: self.message.1?.firstName ?? "This User")
            if status == 3 {
                self.acceptedStatusLabel.text = "You have been accepted to complete this task!"
            }
        })
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .white
        
        setupViews()
    }
    
    fileprivate func setupViews() {
        let bottomSeperatorView = UIView()
        bottomSeperatorView.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.5)
        
        addSubview(bottomSeperatorView)
        bottomSeperatorView.anchor(top: self.topAnchor, left: self.leftAnchor, bottom: nil, right: self.rightAnchor, paddingTop: 100, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)

        addSubview(profileImageView)
        profileImageView.anchor(top: self.topAnchor, left: self.leftAnchor, bottom: nil, right: nil, paddingTop: 25, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        profileImageView.layer.cornerRadius = 50/2
        
        //Add button over profileImageView to view user's profile
        let button = UIButton()
        button.backgroundColor = nil
        addSubview(button)
        button.anchor(top: profileImageView.topAnchor, left: profileImageView.leftAnchor, bottom: profileImageView.bottomAnchor, right: profileImageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        button.layer.cornerRadius = 50/2
        button.addTarget(self, action: #selector(handleProfileImageView), for: .touchUpInside)
        
        
        addSubview(taskTitleLabel)
        taskTitleLabel.anchor(top: self.topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: self.rightAnchor, paddingTop: 4, paddingLeft: 8, paddingBottom: 0, paddingRight: -8, width: nil, height: 22)
        
        addSubview(nameLabel)
        nameLabel.anchor(top: taskTitleLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: self.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: -8, width: nil, height: 20)
        
        addSubview(viewTaskButton)
        viewTaskButton.anchor(top: nil, left: nil, bottom: bottomSeperatorView.topAnchor, right: self.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -4, paddingRight: -8, width: 112, height: 25)
        viewTaskButton.layer.cornerRadius = 12
        
        addSubview(messageTextLabel)
        messageTextLabel.anchor(top: nameLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: self.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: -8, width: nil, height: 20)
        
        addSubview(timeLabel)
        timeLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: bottomSeperatorView.topAnchor, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: -4, paddingRight: 0, width: 100, height: 20)
        
        addSubview(acceptButton)
        acceptButton.anchor(top: bottomSeperatorView.topAnchor, left: nil, bottom: self.bottomAnchor, right: self.rightAnchor, paddingTop: 4, paddingLeft: 0, paddingBottom: -4, paddingRight: -8, width: 112, height: 25)
        acceptButton.layer.cornerRadius = 12
        
        addSubview(acceptedStatusLabel)
        acceptedStatusLabel.anchor(top: bottomSeperatorView.topAnchor, left: self.leftAnchor, bottom: self.bottomAnchor, right: acceptButton.leftAnchor, paddingTop: 4, paddingLeft: 16, paddingBottom: -4, paddingRight: -8, width: nil, height: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
