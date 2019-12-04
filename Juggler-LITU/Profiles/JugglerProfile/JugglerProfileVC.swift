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
    
    //MARK: Stored properties
    var juggler: User?
    
    var reviews = [Review]()
    var rating: Double?
    
    var acceptedTasks = [Task]()
    var completedTasks = [Task]()
    
    // currentHeaderButton values
    // 0 == acceptedButton
    // 1 == completedButton
    // 2 == reviewsButton
    var currentHeaderButton = 0
    
    let noResultsView: UIView = {
        let view = UIView.noResultsView(withText: "No Results Found.")
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    fileprivate func showNoResultsFoundView() {
        print("Show no  Results: \(self.acceptedTasks.count)")
        self.collectionView?.reloadData()
        self.collectionView?.refreshControl?.endRefreshing()
        DispatchQueue.main.async {
            self.collectionView?.addSubview(self.noResultsView)
            self.noResultsView.centerYAnchor.constraint(equalTo: (self.collectionView?.centerYAnchor)!).isActive = true
            self.noResultsView.centerXAnchor.constraint(equalTo: (self.collectionView?.centerXAnchor)!).isActive = true
        }
    }
    
    fileprivate func removeNoResultsView() {
        print("Remove no results: \(self.acceptedTasks.count)")
        self.collectionView?.reloadData()
        self.collectionView?.refreshControl?.endRefreshing()
        DispatchQueue.main.async {
            self.noResultsView.removeFromSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasJugglerBeenAccepted()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        
        // Register all collection view cells
        collectionView?.register(JugglerProfileHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Constants.CollectionViewCellIds.jugglerProfileHeaderCell)
        collectionView.register(AcceptedTaskCell.self, forCellWithReuseIdentifier: Constants.CollectionViewCellIds.acceptedTaskCell)
        collectionView.register(CompletedTaskCell.self, forCellWithReuseIdentifier: Constants.CollectionViewCellIds.completedTaskCell)
        collectionView.register(ReviewCell.self, forCellWithReuseIdentifier: Constants.CollectionViewCellIds.reviewCell)
        
        // Manualy refresh the collectionView
        let refreshController = UIRefreshControl()
        refreshController.tintColor = UIColor.mainBlue()
        refreshController.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshController
        
        setupSettingsBarButton()
        
        guard let jugglerId = Auth.auth().currentUser?.uid else { fatalError() }
        self.fetchJuggler(forUserID: jugglerId)
    }
    
    // Re-fetch data when collection view is refreshed.
    @objc fileprivate func handleRefresh() {
        guard let jugglerId = Auth.auth().currentUser?.uid else { fatalError("No jugglerId") }
        fetchJuggler(forUserID: jugglerId)
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
    
    fileprivate func fetchJuggler(forUserID userID: String) {
        Database.fetchJuggler(userID: userID) { (usr) in
            if let juggler = usr, juggler.isJuggler {
                self.fetchJuggerTasks(forJugglerId: juggler.uid)
                self.fetchReviews(forJugglerId: juggler.uid)
                self.juggler = juggler
                self.navigationItem.title = juggler.firstName + " " + juggler.lastName
                self.collectionView.reloadData()
            }
        }
    }
    
    // Retrieve tasks related to juggler
    fileprivate func fetchJuggerTasks(forJugglerId jugglerId: String) {
        
        let acceptedTasksRef = Database.database().reference().child(Constants.FirebaseDatabase.jugglerTasks).child(jugglerId)
        acceptedTasksRef.observeSingleEvent(of: .value, with: { (jugglerTasksSnapshot) in
            // Empty arrays and dictionaries to allow new values to be stored
            self.acceptedTasks.removeAll()
            
            guard let jugglerTasksSnapshotDictionary = jugglerTasksSnapshot.value as? [String : [String : Any]] else {
                self.showNoResultsFoundView()
                return
            }
            
            jugglerTasksSnapshotDictionary.forEach { (taskOwnerId, taskIds) in
                taskIds.keys.forEach { (taskId) in
                    
                    let tasksRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(taskOwnerId).child(taskId)
                    tasksRef.observeSingleEvent(of: .value, with: { (taskSnapshot) in
                        
                        guard let taskSnapshotDictionary = taskSnapshot.value as? [String : Any] else {
                            self.showNoResultsFoundView()
                            return
                        }

                        let task = Task(id: taskId, dictionary: taskSnapshotDictionary)
                        self.appendAndSort(task: task)
                        
                    
                        // Rearrange arrays to be from most recent to oldest
                        self.acceptedTasks.sort(by: { (task1, task2) -> Bool in
                            return task1.creationDate.compare(task2.creationDate) == .orderedDescending
                        })
//                        self.completedTasks.sort(by: { (task1, task2) -> Bool in
//                            return task1.creationDate.compare(task2.creationDate) == .orderedDescending
//                        })

                        // currentHeaderButton values
                        // 0 == acceptedButton
                        // 1 == completedButton
                        // 2 == reviewsButton
                        if self.currentHeaderButton == 0 {
                            if self.acceptedTasks.isEmpty {
                                self.showNoResultsFoundView()
                            } else {
                                self.removeNoResultsView()
                            }
                        } else if self.currentHeaderButton == 1 {
                            if self.completedTasks.isEmpty {
                                self.showNoResultsFoundView()
                            } else {
                                self.removeNoResultsView()
                            }
                        } else if self.currentHeaderButton == 2 {
                            if self.reviews.isEmpty {
                                self.showNoResultsFoundView()
                            } else {
                                self.removeNoResultsView()
                            }
                        }
                    }) { (error) in
                        self.showNoResultsFoundView()
                        print("UserProfileVC/fetchUsersTasks(): Error fetching user's tasks: ", error)
                    }
                }
            }
        }) { (error) in
            self.showNoResultsFoundView()
            print("JugglerProfileVC/FetchJugglerTasks(): \(error)")
        }
    }
    
    fileprivate func appendAndSort(task: Task) {
        if task.status == 1 {
            self.acceptedTasks.append(task)
        }
    }
    
    fileprivate func fetchReviews(forJugglerId jugglerId: String) {
        print("Fetching Reviews... Not really 😂")
    }
    
    func calculateRating() {
        var totalStars: Double = 0
        
        for review in self.reviews {
            totalStars += Double(review.intRating)
        }
        
        let outOfFive = Double(totalStars/Double(reviews.count))
        self.rating = outOfFive
        
        DispatchQueue.main.async {
            self.removeNoResultsView()
        }
    }
    
    //MARK: UserProfileHeaderCell Methods
    // Add section header for collectionView a supplementary kind
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Constants.CollectionViewCellIds.jugglerProfileHeaderCell, for: indexPath) as? JugglerProfileHeaderCell else { fatalError("Unable to dequeue UserProfileHeaderCell")}
        
        headerCell.juggler = self.juggler
        headerCell.delegate = self
        headerCell.rating = self.rating
                
        return headerCell
    }
    
    // Need to provide a size or the header will not render out
    // Define the size of the section header for the collectionView
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: view.frame.width, height: 265)
    }
    
    //MARK: CollectionView cell methods
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // currentHeaderButton values
        // 0 == acceptedButton
        // 1 == completedButton
        // 2 == reviewsButton
        if currentHeaderButton == 0 {
            if self.acceptedTasks.count == 0 {
                self.showNoResultsFoundView()
                return 0
            } else {
                self.removeNoResultsView()
                return self.acceptedTasks.count
            }
        } else if currentHeaderButton == 1 {
            if self.completedTasks.count == 0 {
                self.showNoResultsFoundView()
                return 0
            } else {
                self.removeNoResultsView()
                return self.completedTasks.count
            }
        } else if currentHeaderButton == 2 {
            if self.reviews.count == 0 {
                self.showNoResultsFoundView()
                return 0
            } else {
                self.removeNoResultsView()
                return self.reviews.count
            }
        }
        
        self.showNoResultsFoundView()
        return 0
    }
    
    // What's the vertical spacing between each cell ?
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if currentHeaderButton == 0 { // Accepted
            if self.acceptedTasks.count >= indexPath.item {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CollectionViewCellIds.acceptedTaskCell, for: indexPath) as! AcceptedTaskCell
                
                if self.acceptedTasks.isEmpty {
                    return AcceptedTaskCell()
                }
                
                let task = self.acceptedTasks[indexPath.item]
                
                cell.acceptedTaskArrayIndex = indexPath.item
                cell.userId = task.userId
                cell.task = task
                cell.delegate = self
                cell.isCurrentUserJuggler = true

                return cell
            }
        } else if currentHeaderButton == 1 { // Completed
            if self.completedTasks.count >= indexPath.item {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CollectionViewCellIds.completedTaskCell, for: indexPath) as! CompletedTaskCell
                
                let task = self.completedTasks[indexPath.item]
                
                cell.userId = task.userId
                cell.task = task
                cell.delegate = self
                
                return cell
            }
        } else if currentHeaderButton == 2 { // Reviews
            if self.reviews.count >= indexPath.item {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CollectionViewCellIds.reviewCell, for: indexPath) as! ReviewCell
                
                cell.review = self.reviews[indexPath.item]
                cell.delegate = self
                
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if self.currentHeaderButton == 2 { // Reviews
            var height: CGFloat = 80
            let review = self.reviews[indexPath.item].reviewString
            
            height = self.estimatedFrameForReviewCell(fromText: review).height + 55
            
            if height < 101 {
                return CGSize(width: view.frame.width, height: 110)
            } else {
                return CGSize(width: view.frame.width, height: height)
            }
        } else {
            
            return CGSize(width: view.frame.width, height: 100)
        }
    }
    
    fileprivate func estimatedFrameForReviewCell(fromText text: String) -> CGRect {
        //Height must be something really tall and width is the same as chatBubble in ChatMessageCell
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [.font : UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var selectedTask: Task?
        
        if currentHeaderButton == 0 { // Accepted tasks
            selectedTask = self.acceptedTasks[indexPath.item]
        } else if currentHeaderButton == 1 { // Completed tasks
            selectedTask = self.completedTasks[indexPath.item]
        } else { // Reviews
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
            if let juggler = jglr {
                MainTabBarController.isJugglerAccepted = true
                DispatchQueue.main.async {
                    self.juggler = juggler
                    self.navigationItem.title = juggler.firstName + " " + juggler.lastName
                    self.collectionView?.reloadData()
                }
            } else {
                
                MainTabBarController.isJugglerAccepted = false
                self.present(UINavigationController(rootViewController: ApplicationPendingVC()), animated: true, completion: nil)
            }
        }
    }
}

//MARK: JugglerProfileHeaderCellDelegate AND AcceptedTaskCellJugglerDelegate methods
extension JugglerProfileVC: JugglerProfileHeaderCellDelegate, AcceptedTaskCellJugglerDelegate {
    func toolBarValueChanged(fromButton button: Int) {
        if self.currentHeaderButton != button {
            self.currentHeaderButton = button
            self.collectionView.reloadData()
        }
    }
    
    func showUserProfile(withUserId userId: String?) {
        if let userId = userId {
            Database.fetchUserFromUserID(userID: userId) { (usr) in
                if let user = usr {
                    
                    let userProfileVC = UserProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
                    userProfileVC.user = user
                    
                    self.navigationController?.pushViewController(userProfileVC, animated: true)
                    
                } else {
                    self.showCannotLoadUserAlert()
                }
            }
        } else {
         self.showCannotLoadUserAlert()
        }
    }
    
    fileprivate func showCannotLoadUserAlert() {
        let alert = UIView.okayAlert(title: "Cannot Load User", message: "We are currently unable to load this user's profile. Please try again.")
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleCompleteTaskButton(forTask task: Task?, userId: String?, acceptedTaskArrayIndex: Int?, completion: @escaping (Bool) -> Void) {
        guard let task = task, let currentuserID = Auth.auth().currentUser?.uid else {
            completion(false); return
        }
        
        if task.isJugglerComplete {
            explainCompletionProcess()
            completion(true)
            return
        }
        
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { (_) in
            if currentuserID != task.mutuallyAcceptedBy {
                completion(false); return
            }
            
            let taskRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(task.userId).child(task.id)
            taskRef.updateChildValues([Constants.FirebaseDatabase.isJugglerComplete : 1]) { (err, _) in
                if let error = err {
                    print("ERROR COMPLETING TASK: \(error)")
                    completion(false)
                    return
                }
                
                if let acceptedTaskArrayIndex = acceptedTaskArrayIndex {
                    self.acceptedTasks[acceptedTaskArrayIndex].isJugglerComplete = true
                }
                
                completion(true)
                self.explainCompletionProcess()
            }
        }
        
        let alert = UIAlertController(title: "Task Completed?", message: "Are you sure? DO NOT TAP 'Yes' if you have not completed this task!", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(false)
        }
        alert.addAction(cancelAction)
        alert.addAction(yesAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func explainCompletionProcess() {
        DispatchQueue.main.async {
            let okayAlert = UIView.okayAlert(title: "Task Under Completion", message: "User has 48 hours to agree or deny task completion. Task will then be fully completed and compensated!")
            self.present(okayAlert, animated: true, completion: nil)
        }
    }
    
    fileprivate func unableAlert() {
        let alert = UIView.okayAlert(title: "Unable to Complete Task", message: "Sorry for the inconvenience. PLease try again later")
        self.display(alert: alert)
    }
}

//MARK: CompletedTaskCellJugglerDelegate methods
extension JugglerProfileVC: CompletedTaskCellJugglerDelegate {
    func showUserProfile(forUserId userId: String?) {
        if let userId = userId {
            Database.fetchUserFromUserID(userID: userId) { (usr) in
                if let user = usr {
                    
                    let userProfileVC = UserProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
                    userProfileVC.user = user
                    
                    self.navigationController?.pushViewController(userProfileVC, animated: true)
                    
                } else {
                    self.showCannotLoadUserAlert()
                }
            }
        } else {
            self.showCannotLoadUserAlert()
        }
    }
}

//MARK: ReviewCellJugglerDelegate methods
extension JugglerProfileVC: ReviewCellJugglerDelegate {
    func showUserProfile(userId: String?) {
        if let userId = userId {
            Database.fetchUserFromUserID(userID: userId) { (usr) in
                if let user = usr {
                    
                    let userProfileVC = UserProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
                    userProfileVC.user = user
                    
                    self.navigationController?.pushViewController(userProfileVC, animated: true)
                    
                } else {
                    self.showCannotLoadUserAlert()
                }
            }
        } else {
            self.showCannotLoadUserAlert()
        }
    }
}
