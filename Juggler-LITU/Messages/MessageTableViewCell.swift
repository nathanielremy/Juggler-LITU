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
        let attributedText = NSMutableAttributedString(string: "Status: ", attributes: [.font : UIFont.systemFont(ofSize: 12), .foregroundColor : UIColor.gray])
        
        if status == 0 {
            attributedText.append(NSAttributedString(string: "Pending", attributes: [.font : UIFont.boldSystemFont(ofSize: 12), .foregroundColor : UIColor.mainBlue()]))
        } else if status == 1 {
            attributedText.append(NSAttributedString(string: "Accepted", attributes: [.font : UIFont.boldSystemFont(ofSize: 12), .foregroundColor : UIColor.mainBlue()]))
        } else {
            attributedText.append(NSAttributedString(string: "Completed", attributes: [.font : UIFont.boldSystemFont(ofSize: 12), .foregroundColor : UIColor.mainBlue()]))
        }
        
        taskStatusLabel.attributedText = attributedText
    }
    
    var message: (Message?, User?) {
        didSet {
            guard let theMessage = message.0, let user = message.1 else {
                print("No message or user"); return
            }
            
            profileImageView.loadImage(from: user.profileImageURLString)
            fetchTaskFor(userId: theMessage.taskOwnerId, taskId: theMessage.taskId)
            nameLabel.text = user.fullName
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
        iv.isUserInteractionEnabled = true
        
        return iv
    }()
    
    @objc func handleProfileImageView() {
        guard let user = message.1 else { return }
        delegate?.handleProfileImageView(forUser: user)
    }
    
    let taskStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        
        return label
    }()
    
    lazy var viewTaskButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View Task", for: .normal)
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .white
        
        setupViews()
    }
    
    fileprivate func setupViews() {
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: self.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 50/2
        
        //Add button over profileImageView to view user's profile
        let button = UIButton()
        button.backgroundColor = nil
        addSubview(button)
        button.anchor(top: profileImageView.topAnchor, left: profileImageView.leftAnchor, bottom: profileImageView.bottomAnchor, right: profileImageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        button.layer.cornerRadius = 50/2
        button.addTarget(self, action: #selector(handleProfileImageView), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [taskStatusLabel, viewTaskButton])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        
        addSubview(taskTitleLabel)
        taskTitleLabel.anchor(top: self.topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: self.rightAnchor, paddingTop: 4, paddingLeft: 8, paddingBottom: 0, paddingRight: -8, width: nil, height: 22)
        
        addSubview(nameLabel)
        nameLabel.anchor(top: taskTitleLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: self.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: -8, width: nil, height: 20)
        
        addSubview(stackView)
        stackView.anchor(top: nameLabel.bottomAnchor, left: nil, bottom: self.bottomAnchor, right: self.rightAnchor, paddingTop: -10, paddingLeft: 0, paddingBottom: -4, paddingRight: -8, width: 112, height: nil)
        viewTaskButton.layer.cornerRadius = 13
        
        addSubview(messageTextLabel)
        messageTextLabel.anchor(top: nameLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: stackView.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: -8, width: nil, height: 20)
        
        addSubview(timeLabel)
        timeLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: self.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: -4, paddingRight: 0, width: 100, height: 20)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
