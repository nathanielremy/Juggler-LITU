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
    func handleAcceptUser(forTask task: Task?, user: User?, completion: @escaping (Bool) -> Void)
}

class MessageTableViewCell: UITableViewCell {
    
    //MARK: Stores properties
    var delegate: MessageTableViewCellDelegate?
    var task: Task? {
        didSet {
            if let task = task {
                self.taskTitleLabel.text = task.title
                self.displayTaskStatus(forStatus: task.status)
                return
            } else {
                self.taskTitleLabel.text = "Task Deleted"
                print("Task property is nil")
                return
            }
        }
    }
    
    fileprivate func displayTaskStatus(forStatus status: Int) {
        if status == 1 { // Task is sccepted
            acceptButton.setTitle("Accepted", for: .normal)
            acceptButton.isEnabled = false
        } else if status == 2 { // Task is completed
            acceptButton.setTitle("Completed", for: .normal)
            acceptButton.isEnabled = false
        } else { // Task is pending
            acceptButton.setTitle("Accept Juggler", for: .normal)
            acceptButton.isEnabled = true
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
    
    lazy var acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Accept Juggler", for: .normal)
        button.backgroundColor = UIColor.mainBlue()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.isEnabled = false
        button.addTarget(self, action: #selector(handleAcceptedButton), for: .touchUpInside)
        
        return button
    }()
    
    @objc fileprivate func handleAcceptedButton() {
        delegate?.handleAcceptUser(forTask: self.task, user: self.message.1, completion: { (success) in
            print(success)
        })
    }
    
    let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkText
        label.textAlignment = .left
        label.numberOfLines = 0
        
        label.text = "HEy this is some random text for this label"
        
        return label
    }()
    
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
        
        addSubview(statusLabel)
        statusLabel.anchor(top: bottomSeperatorView.topAnchor, left: self.leftAnchor, bottom: self.bottomAnchor, right: acceptButton.leftAnchor, paddingTop: 4, paddingLeft: 16, paddingBottom: -4, paddingRight: -8, width: nil, height: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
