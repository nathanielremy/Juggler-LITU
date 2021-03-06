//
//  UserProfileVC.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 21/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

class UserProfileVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    //MARK: Stored properties
    var user: User? {
        didSet {
            guard let userId = user?.uid else {
                print("UserProfileVC: No user")
                return
            }
            
            if canFetchTasks {
                //Empty all temp arrays to allow new values to be stored
                self.tempPendingTasks.removeAll()
                self.tempAcceptedTasks.removeAll()
                self.tempCompletedTasks.removeAll()
                
                self.fetchUsersTasks(forUserId: userId)
            }
        }
    }
    
    var pendingTasks = [Task]()
    var tempPendingTasks = [Task]()
    
    var acceptedTasks = [Task]()
    var tempAcceptedTasks = [Task]()
    
    var completedTasks = [Task]()
    var tempCompletedTasks = [Task]()
    
    var canFetchTasks = true
    
    // currentHeaderButton values
    // 0 == pendingButton
    // 1 == acceptedButton
    // 2 == completedButton
    var currentHeaderButton = 0
    
    // Display when first loading profile
    let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView()
        ai.hidesWhenStopped = true
        ai.color = UIColor.mainBlue()
        ai.translatesAutoresizingMaskIntoConstraints = false
        
        return ai
    }()
    
    func animateAndShowActivityIndicator(_ bool: Bool) {
        if bool {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
    }
    
    let noResultsView: UIView = {
        let view = UIView.noResultsView(withText: "No Results Found.")
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    fileprivate func showNoResultsFoundView(andReload reload: Bool) {
        if reload {
            self.collectionView?.refreshControl?.endRefreshing()
            self.collectionView?.reloadData()
        }
        DispatchQueue.main.async {
            self.collectionView?.addSubview(self.noResultsView)
            self.noResultsView.centerYAnchor.constraint(equalTo: (self.collectionView?.centerYAnchor)!).isActive = true
            self.noResultsView.centerXAnchor.constraint(equalTo: (self.collectionView?.centerXAnchor)!).isActive = true
        }
    }
    
    fileprivate func removeNoResultsView() {
        self.collectionView?.refreshControl?.endRefreshing()
        DispatchQueue.main.async {
            self.noResultsView.removeFromSuperview()
            self.collectionView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        
        // Register all collection view cells
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Constants.CollectionViewCellIds.userProfileHeaderCell)
        collectionView.register(PendingTaskCell.self, forCellWithReuseIdentifier: Constants.CollectionViewCellIds.pendingTaskCell)
        collectionView.register(AcceptedTaskCell.self, forCellWithReuseIdentifier: Constants.CollectionViewCellIds.acceptedTaskCell)
        collectionView.register(CompletedTaskCell.self, forCellWithReuseIdentifier: Constants.CollectionViewCellIds.completedTaskCell)
        
        collectionView?.alwaysBounceVertical = true
        
        // Manualy refresh the collectionView
        let refreshController = UIRefreshControl()
        refreshController.tintColor = UIColor.mainBlue()
        refreshController.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        collectionView.refreshControl = refreshController
        
        self.setupActivityIndicator()
        self.animateAndShowActivityIndicator(true)
    }
    
    fileprivate func setupActivityIndicator() {
        view.addSubview(self.activityIndicator)
        self.activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    @objc fileprivate func handleRefresh() {
        guard let userId = self.user?.uid else { fatalError() }
        self.fetchUser(forUserId: userId)
        
        if canFetchTasks {
            //Empty all temp arrays to allow new values to be stored
            self.tempPendingTasks.removeAll()
            self.tempAcceptedTasks.removeAll()
            self.tempCompletedTasks.removeAll()
            
            self.fetchUsersTasks(forUserId: userId)
        }
    }
    
    //Fetch user to populate UI and fetch appropriate data.
    fileprivate func fetchUser(forUserId userId: String) {
        Database.fetchUserFromUserID(userID: userId) { (user) in
            if let user = user {
                self.user = user
                DispatchQueue.main.async {
                    self.navigationItem.title = user.firstName + " " + user.lastName
                }
            } else {
                // Crash the app if no user is returned from the above function call.
                fatalError("Could not load user in UserProfileVC...")
            }
        }
    }
    
    //MARK: Retrieve tasks for user
    fileprivate func fetchUsersTasks(forUserId userId: String) {
        if !canFetchTasks {
            return
        }
        
        self.canFetchTasks = false
        
        let tasksRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).queryOrdered(byChild: Constants.FirebaseDatabase.userId).queryEqual(toValue: userId)
        tasksRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let snapshotDictionary = snapshot.value as? [String : [String : Any]] else {
                self.pendingTasks.removeAll()
                self.acceptedTasks.removeAll()
                self.completedTasks.removeAll()
                self.canFetchTasks = true
                self.showNoResultsFoundView(andReload: true)
                self.animateAndShowActivityIndicator(false)
                return
            }
            
            var tasksCreated = 0
            snapshotDictionary.forEach { (taskId, taskDictionary) in
                let task = Task(id: taskId, dictionary: taskDictionary)
                tasksCreated += 1
                
                // task.status values
                // 0 == pendingButton
                // 1 == acceptedButton
                // 2 == completedButton
                if task.status == 0 { // Pending
                    self.tempPendingTasks.append(task)
                } else if task.status == 1 { // Accepted
                    self.tempAcceptedTasks.append(task)
                } else if task.status == 2 { // Completed
                    self.tempCompletedTasks.append(task)
                }
                
                // Re-arrange all task arrays from youngest to oldest
                self.tempPendingTasks.sort(by: { (task1, task2) -> Bool in
                    return task1.creationDate.compare(task2.creationDate) == .orderedDescending
                })
                self.tempAcceptedTasks.sort(by: { (task1, task2) -> Bool in
                    return task1.creationDate.compare(task2.creationDate) == .orderedDescending
                })
                self.tempCompletedTasks.sort(by: { (task1, task2) -> Bool in
                    return task1.completionDate.compare(task2.completionDate) == .orderedDescending
                })
                
                if tasksCreated == snapshotDictionary.count {
                    self.pendingTasks = self.tempPendingTasks
                    self.acceptedTasks = self.tempAcceptedTasks
                    self.completedTasks = self.tempCompletedTasks
                    self.removeNoResultsView()
                    self.canFetchTasks = true
                    self.animateAndShowActivityIndicator(false)
                    return
                }
            }
        }) { (error) in
            self.pendingTasks.removeAll()
            self.acceptedTasks.removeAll()
            self.completedTasks.removeAll()
            self.canFetchTasks = true
            self.showNoResultsFoundView(andReload: true)
            self.animateAndShowActivityIndicator(false)
            print("UserProfileVC/fetchUsersTasks(): Error fetching user's tasks: ", error)
        }
    }
    
    //MARK: UserProfileHeaderCell Methods
    // Add section header for collectionView a supplementary kind
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Constants.CollectionViewCellIds.userProfileHeaderCell, for: indexPath) as? UserProfileHeader else { fatalError("Unable to dequeue UserProfileHeaderCell")}
        
        headerCell.delegate = self
        headerCell.user = self.user
        
        return headerCell
    }
    
    // Need to provide a size or the header will not render out
    // Define the size of the section header for the collectionView
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: view.frame.width, height: 203)
    }
    
    //MARK: Collection view methods
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if currentHeaderButton == 0 {
            if self.pendingTasks.count == 0 {
                self.showNoResultsFoundView(andReload: false)
            }
            return self.pendingTasks.count
        } else if currentHeaderButton == 1 {
            if self.acceptedTasks.count == 0 {
                self.showNoResultsFoundView(andReload: false)
            }
            return self.acceptedTasks.count
        } else {
            if self.completedTasks.count == 0 {
                self.showNoResultsFoundView(andReload: false)
            }
            return self.completedTasks.count
        }
    }
    
    // What's the vertical spacing between each cell ?
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if currentHeaderButton == 0 { // Use PendingTaskCell
            if self.pendingTasks.count >= indexPath.item {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CollectionViewCellIds.pendingTaskCell, for: indexPath) as! PendingTaskCell
                
                cell.task = self.pendingTasks[indexPath.item]
                cell.profileImageView.loadImage(from: self.user?.profileImageURLString ?? "")
                cell.user = self.user
                
                return cell
            }
        } else if currentHeaderButton == 1 { // Use AcceptedTaskCell
            if self.acceptedTasks.count >= indexPath.item {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CollectionViewCellIds.acceptedTaskCell, for: indexPath) as! AcceptedTaskCell
                
                let task = self.acceptedTasks[indexPath.item]
                
                cell.jugglerId = task.mutuallyAcceptedBy
                cell.task = task
                
                return cell
            }
        } else if currentHeaderButton == 2 { // Use CompletedTaskCell
            if self.completedTasks.count >= indexPath.item {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CollectionViewCellIds.completedTaskCell, for: indexPath) as! CompletedTaskCell
                
                let task = self.completedTasks[indexPath.item]
                
                cell.jugglerId = task.mutuallyAcceptedBy
                // Cell's task property MUST be set before cell's isUser property
                cell.task = task
                
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 100)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var selectedTask: Task?
        
        if currentHeaderButton == 0 { // Pending tasks
            selectedTask = self.pendingTasks[indexPath.item]
        } else if currentHeaderButton == 1 { // Accepted tasks
            selectedTask = self.acceptedTasks[indexPath.item]
        } else if currentHeaderButton == 2 { // Completedtasks
            selectedTask = self.completedTasks[indexPath.item]
        } else { // Just in case lol
            return
        }
        
        guard let task = selectedTask else { return }
        
        let taskDetailsVC = TaskDetailsVC()
        taskDetailsVC.task = task
        
        navigationController?.pushViewController(taskDetailsVC, animated: true)
    }
    
    fileprivate func display(alert: UIAlertController) {
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

//MARK: UserProfileHeaderCellDelegate methods
extension UserProfileVC: UserProfileHeaderCellDelegate {
    func toolBarValueChanged(fromButton button: Int) {
        self.noResultsView.removeFromSuperview()
        
        if self.currentHeaderButton != button {
            self.currentHeaderButton = button
            self.collectionView.reloadData()
        }
    }
}
