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
    
    //MARK: Stored properties
    var messages = [Message]()
    var messagesDictionary = [String : Message]()
    var timer: Timer?
    
    let noResultsView: UIView = {
        let view = UIView.noResultsView(withText: "No New Messages.")
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    fileprivate func showNoResultsFoundView() {
        DispatchQueue.main.async {
            self.tableView?.addSubview(self.noResultsView)
            self.noResultsView.centerYAnchor.constraint(equalTo: (self.tableView?.centerYAnchor)!).isActive = true
            self.noResultsView.centerXAnchor.constraint(equalTo: (self.tableView?.centerXAnchor)!).isActive = true
        }
    }
    
    fileprivate func removeNoResultsView() {
        DispatchQueue.main.async {
            self.noResultsView.removeFromSuperview()
        }
    }
    
    let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView()
        ai.hidesWhenStopped = true
        ai.color = UIColor.mainBlue()
        ai.translatesAutoresizingMaskIntoConstraints = false
        
        return ai
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasJugglerBeenAccepted()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Messages"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        // Manualy refresh the collectionView
        let refreshController = UIRefreshControl()
        refreshController.tintColor = UIColor.mainBlue()
        refreshController.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        tableView.refreshControl = refreshController
        
        // Register table view cell
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: Constants.TableViewCellIds.messageTableViewCell)
        
        
        observeUserMessages()
    }
    
    @objc fileprivate func handleRefresh() {
        observeUserMessages()
    }
    
    fileprivate func observeUserMessages() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { print("Could not fetch currentUserId"); self.disableAndAnimate(false); return }
        
        let ref = Database.database().reference().child(Constants.FirebaseDatabase.userMessagesRef).child(currentUserId)
        
        ref.observe(.childAdded, with: { (snapShot) in
            
            self.disableAndAnimate(true)
            
            let userId = snapShot.key
            let userRef = Database.database().reference().child(Constants.FirebaseDatabase.userMessagesRef).child(currentUserId).child(userId)
            
            userRef.observe(.childAdded, with: { (snapshot2) in
                
                self.disableAndAnimate(true)
                
                let messageId = snapshot2.key
                self.fetchMessage(withMessageId: messageId)
                
            }, withCancel: { (error) in
                print("Error fetching messages: ", error); self.disableAndAnimate(false); return
            })
        }) { (error) in
            print("ERROR: ", error); self.disableAndAnimate(false); return
        }
        
        ref.observe(.childRemoved, with: { (snapshot3) in
            self.messagesDictionary.removeValue(forKey: snapshot3.key)
            self.attemptReloadTable()
        }) { (error) in
            print("Error fetching data when child removed: ", error); self.disableAndAnimate(false); return
        }
        self.disableAndAnimate(false)
    }
    
    fileprivate func attemptReloadTable() {
        //Solution to only reload tableView once
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.handleReloadTableView), userInfo: nil, repeats: false)
    }
    
    @objc func handleReloadTableView() {
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (msg1, msg2) -> Bool in
            return Double(msg1.timeStamp.timeIntervalSince1970) > Double(msg2.timeStamp.timeIntervalSince1970)
        })
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    fileprivate func fetchMessage(withMessageId messageId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { print("Ni current user"); self.disableAndAnimate(false); return }
        
        let messagesRef = Database.database().reference().child(Constants.FirebaseDatabase.messagesRef).child(messageId)
        
        self.disableAndAnimate(false)
        
        messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.disableAndAnimate(true)
            
            guard let dictionary = snapshot.value as? [String : Any] else { print("snapShot not convertible to [String : Any]"); self.disableAndAnimate(false); return }
            
            let message = Message(key: snapshot.key, dictionary: dictionary)
            
            //Grouping all messages per user and Jugglers cannot message about their own tasks
            if let chatPartnerId = message.chatPartnerId(), currentUserId != message.taskOwnerId {
                self.messagesDictionary[chatPartnerId] = message
            }
            
            //Solution to only reload tableView once
            self.attemptReloadTable()
            self.disableAndAnimate(false)
            
        }, withCancel: { (error) in
            print("ERROR: ", error); self.disableAndAnimate(false); return
        })
    }
    
    func prepareChatController(forUser user: User, indexPath: Int, taskOwner: String) {
        let taskId = self.messages[indexPath].taskId
        
        let taskRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(taskId)
        taskRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String : Any] else {
                DispatchQueue.main.async {
                    self.disableAndAnimate(false)
                }
                self.showChatController(forTask: nil, user: user)
                print("Could not convert snapshot to [String : Any]"); return
            }
            
            let task = Task(id: snapshot.key, dictionary: dictionary)
            self.showChatController(forTask: task, user: user)
            
        }) { (error) in
            print("Error fetching task: ", error); return
        }
    }
    
    func showChatController(forTask task: Task?, user: User) {
        DispatchQueue.main.async {
            self.disableAndAnimate(false)
            let chatLogVC = ChatLogVC(collectionViewLayout: UICollectionViewFlowLayout())
            chatLogVC.data = (user, task)
            self.navigationController?.pushViewController(chatLogVC, animated: true)
        }
    }
    
    //MARK: TableView Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.messages.count == 0 {
            self.showNoResultsFoundView()
        } else {
            self.removeNoResultsView()
        }
        
        return self.messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TableViewCellIds.messageTableViewCell, for: indexPath) as! MessageTableViewCell
        
        let message = self.messages[indexPath.row]
        
        if let uId = message.chatPartnerId() {
            Database.fetchUserFromUserID(userID: uId) { (userr) in
                guard let user = userr else { print("Could not fetch user from Database"); return }
                DispatchQueue.main.async {
                    cell.message = (message, user)
                    cell.delegate = self
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 133
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.disableAndAnimate(true)
        let message = self.messages[indexPath.row]
        
        //Select correct user to show in ChatLogVC
        guard let uId = message.chatPartnerId() else {
            self.disableAndAnimate(false)
            print("No chat partner Id"); return
        }
        Database.fetchUserFromUserID(userID: uId) { (userr) in
            guard let user = userr else {
                self.disableAndAnimate(false)
                print("No user returned from database"); return
            }
            
            DispatchQueue.main.async {
                self.prepareChatController(forUser: user, indexPath: indexPath.row, taskOwner: message.taskOwnerId)
            }
        }
    }
    
    //Enable the tableView to delete messages
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //What happens when user hits delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { print("Could not fetch current user Id"); return }
        guard let chatParterId = self.messages[indexPath.row].chatPartnerId() else { print("Could not fetch chatPartnerId"); return }
        
        let deleteRef = Database.database().reference().child(Constants.FirebaseDatabase.userMessagesRef).child(currentUserId).child(chatParterId)
        deleteRef.removeValue { (err, _) in
            if let error = err {
                print("Error deleting value from database: ", error)
                return
            }
            
            self.messagesDictionary.removeValue(forKey: chatParterId)
            self.attemptReloadTable()
        }
    }
    
    func disableAndAnimate(_ bool: Bool) {
        DispatchQueue.main.async {
            if bool {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
                self.tableView.refreshControl?.endRefreshing()
            }
            self.tableView.isUserInteractionEnabled = !bool
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
        
        if let _ = jugglerCache[userId] {
            jugglerCache.removeValue(forKey: userId)
        }
        
        Database.isJugglerAccepted(userId: userId) { (jglr) in
            if let _ = jglr {
                
                MainTabBarController.isJugglerAccepted = true
                
            } else {
                
                MainTabBarController.isJugglerAccepted = false
                self.present(UINavigationController(rootViewController: ApplicationPendingVC()), animated: true, completion: nil)
            }
        }
    }
}

//MARK: MessageTableViewCellDelegate methods
extension MessagesVC: MessageTableViewCellDelegate {
    func handleViewTaskButton(forTask task: Task?) {
        if let task = task {
            
            let taskDetailsVC = TaskDetailsVC()
            taskDetailsVC.task = task
            navigationController?.pushViewController(taskDetailsVC, animated: true)
            
        } else {
            let alert = UIView.okayAlert(title: "Unable to Load Task", message: "Tap the 'Okay' button and try again.")
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func handleProfileImageView(forUser user: User?) {
        if let user = user {
            
            let userProfileVC = UserProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
            userProfileVC.user = user
            
            navigationController?.pushViewController(userProfileVC, animated: true)
            
        } else {
            let alert = UIView.okayAlert(title: "Unable to Load Task", message: "Tap the 'Okay' button and try again.")
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func handleAcceptUser(forTask task: Task?, user: User?, completion: @escaping (Int) -> Void) {
        guard let task = task, let user = user, let currentuserID = Auth.auth().currentUser?.uid else {
            completion(0); return
        }
        
        if (task.status != 0) || (task.mutuallyAcceptedBy != nil) {
            let okayAlert = UIView.okayAlert(title: "Unable to Accept Task", message: "This task has already been accepted or commpleted")
            self.present(okayAlert, animated: true, completion: nil)
            completion(3); return
        }
        
        if task.taskAccepters?[currentuserID] == nil {
            let acceptRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(task.id).child(Constants.FirebaseDatabase.taskAccepters)
            acceptRef.updateChildValues([currentuserID : 0]) { (err, _) in
                if let error = err {
                    print("ERROR: \(error)")
                    completion(0)
                    return
                }
                
                completion(1) // Means you have accepted them but they havent accepted you back
                
                if task.jugglersAccepted?[currentuserID] != nil {
                    //Update the task's status to accepted (1) and set the mutuallyAcceptedBy value to jugglerID
                    let values: [String : Any] = [
                        Constants.FirebaseDatabase.taskStatus : 1,
                        Constants.FirebaseDatabase.mutuallyAcceptedBy : currentuserID
                    ]
                    
                    let databaseRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(task.id)
                    databaseRef.updateChildValues(values)
                    
                    Database.updateJugglerTasks(forJugglerID: currentuserID, userID: user.uid, task: task, status: 1)
                    
                    completion(3) // Means you have both accepted eachother and the task has been accepted
                }
            }
        }
        
        completion(0)
    }
}
