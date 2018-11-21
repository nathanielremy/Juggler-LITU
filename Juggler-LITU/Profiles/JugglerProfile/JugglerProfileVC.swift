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
    var juggler: Juggler?
    
    var reviews = [Review]()
    var rating: Double?
    
    var acceptedUsers = [String : [String]]()
    var acceptedTasks = [Task]()
    
    var completedUsers = [String : [String]]()
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
        self.collectionView?.reloadData()
        self.collectionView?.refreshControl?.endRefreshing()
        DispatchQueue.main.async {
            self.collectionView?.addSubview(self.noResultsView)
            self.noResultsView.centerYAnchor.constraint(equalTo: (self.collectionView?.centerYAnchor)!).isActive = true
            self.noResultsView.centerXAnchor.constraint(equalTo: (self.collectionView?.centerXAnchor)!).isActive = true
        }
    }
    
    fileprivate func removeNoResultsView() {
        self.collectionView?.reloadData()
        self.collectionView?.refreshControl?.endRefreshing()
        DispatchQueue.main.async {
            self.noResultsView.removeFromSuperview()
        }
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
        refreshController.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshController
        
        setupSettingsBarButton()
        
        if MainTabBarController.isJugglerAccepted != true {
            hasJugglerBeenAccepted()
        }
        
        guard let jugglerId = Auth.auth().currentUser?.uid else { fatalError() }
        self.fetchJuggler(forJugglerId: jugglerId)
        self.fetchJuggerTasks(forJugglerId: jugglerId)
        self.fetchCompletedTasks(forJugglerId: jugglerId)
        self.fetchReviews(forJugglerId: jugglerId)
    }
    
    // Re-fetch data when collection view is refreshed.
    @objc fileprivate func handleRefresh() {
        guard let jugglerId = Auth.auth().currentUser?.uid else { fatalError() }
        fetchJuggler(forJugglerId: jugglerId)
        
        if self.currentHeaderButton == 0 {
            self.fetchJuggerTasks(forJugglerId: jugglerId)
        } else if self.currentHeaderButton == 1 {
            self.fetchCompletedTasks(forJugglerId: jugglerId)
        } else if self.currentHeaderButton == 2 {
            self.fetchReviews(forJugglerId: jugglerId)
        }
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
    
    fileprivate func fetchJuggler(forJugglerId jugglerId: String) {
        Database.fetchJuggler(jugglerID: jugglerId) { (jglr) in
            if let juggler = jglr {
                self.juggler = juggler
                self.navigationItem.title = juggler.fullName
                self.collectionView.reloadData()
            }
        }
    }
    
    // Retrieve tasks related to juggler
    fileprivate func fetchJuggerTasks(forJugglerId jugglerId: String) {
        
        // Fetching accepted tasks
        let acceptedTasksRef = Database.database().reference().child(Constants.FirebaseDatabase.acceptedTasks).child(jugglerId)
        acceptedTasksRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Empty all arrays and dictionaries to allow new values to be stored
            self.acceptedUsers.removeAll()
            self.acceptedTasks.removeAll()
            
            if let snapshotDictionary = snapshot.value as? [String : Any] {
                snapshotDictionary.forEach({ (key, value) in
                    if let valueDictionary = value as? [String : Any] {
                        
                        // Match correct userId with correct taskId
                        valueDictionary.forEach({ (valKey, valValue) in
                            if let _ = self.acceptedUsers[key] {
                                self.acceptedUsers[key]?.append(valKey)
                            } else {
                                self.acceptedUsers[key] = [valKey]
                            }
                            
                            // Fetch task from taskId
                            let taskRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(key).child(valKey)
                            taskRef.observeSingleEvent(of: .value, with: { (snapshot1) in
                                
                                // Create task object and add task to array
                                if let values = snapshot1.value as? [String : Any] {
                                    let task = Task.init(id: snapshot1.key, dictionary: values)
                                    self.acceptedTasks.append(task)
                                }
                                
                                // Rearrange the allTasks and pendingTasks array to be from most recent to oldest
                                self.acceptedTasks.sort(by: { (task1, task2) -> Bool in
                                    return task1.creationDate.compare(task2.creationDate) == .orderedDescending
                                })
                                
                                if self.currentHeaderButton == 0 {
                                    if self.acceptedTasks.isEmpty {
                                        self.showNoResultsFoundView()
                                    } else {
                                        self.removeNoResultsView()
                                    }
                                }
                            })
                        })
                    }
                })
            } else {
                if self.currentHeaderButton == 0 {
                    self.showNoResultsFoundView()
                }
            }
        }) { (error) in
            self.showNoResultsFoundView()
            print("JugglerProfileVC/FetchJugglerTasks(): \(error)")
        }
    }
    
    fileprivate func fetchCompletedTasks(forJugglerId jugglerId: String) {
        // Fetching completed tasks
        let completedTasksRef = Database.database().reference().child(Constants.FirebaseDatabase.completedTasks).child(jugglerId)
        completedTasksRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Empty all arrays and dictionaries to allow new values to be stored
            self.completedUsers.removeAll()
            self.completedTasks.removeAll()
            
            if let snapshotDictionary = snapshot.value as? [String : Any] {
                snapshotDictionary.forEach({ (key, value) in
                    if let valueDictionary = value as? [String : Any] {
                        
                        // Match correct userId with correct taskId
                        valueDictionary.forEach({ (valKey, valValue) in
                            
                            if let _ = self.completedUsers[key] {
                                self.completedUsers[key]?.append(valKey)
                            } else {
                                self.completedUsers[key] = [valKey]
                            }
                            
                            // Fetch task from taskId
                            let taskRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(key).child(valKey)
                            taskRef.observeSingleEvent(of: .value, with: { (snapshot1) in
                                
                                // Create task object and add task to array
                                if let values = snapshot1.value as? [String : Any] {
                                    let task = Task(id: snapshot1.key, dictionary: values)
                                    self.completedTasks.append(task)
                                }
                                
                                // Rearrange the allTasks and pendingTasks array to be from most recent to oldest
                                self.completedTasks.sort(by: { (task1, task2) -> Bool in
                                    return task1.creationDate.compare(task2.creationDate) == .orderedDescending
                                })
                                
                                if self.currentHeaderButton == 1 {
                                    if self.completedTasks.isEmpty {
                                        self.showNoResultsFoundView()
                                    } else {
                                        self.removeNoResultsView()
                                    }
                                }
                            })
                        })
                    }
                })
            } else {
                if self.currentHeaderButton == 1 {
                    self.showNoResultsFoundView()
                }
            }
        }) { (error) in
            self.showNoResultsFoundView()
            print("JugglerProfileVC/FetchJugglerTasks(): \(error)")
        }
    }
    
    fileprivate func fetchReviews(forJugglerId jugglerId: String) {
        let reviewsRef = Database.database().reference().child(Constants.FirebaseDatabase.reviewsRef).child(jugglerId)
        reviewsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String : Any] else {
                self.reviews.removeAll()
                self.rating = 0
                if self.currentHeaderButton == 2 {
                    self.showNoResultsFoundView()
                }
                print("fetchReviews(): Unable to convert to [String:Any]"); return
            }
            
            self.reviews.removeAll()
            
            dictionary.forEach({ (key, value) in
                guard let reviewDictionary = value as? [String : Any] else {
                    if self.currentHeaderButton == 2 {
                        self.showNoResultsFoundView()
                    }
                    return
                }
                
                let review = Review(id: key, dictionary: reviewDictionary)
                self.reviews.append(review)
                
                // Rearrange the reviews array to be from most recent to oldest
                self.reviews.sort(by: { (review1, review2) -> Bool in
                    return review1.creationDate.compare(review2.creationDate) == .orderedDescending
                })
            })
            
            if self.reviews.isEmpty {
                self.rating = 0
                
                if self.currentHeaderButton == 2 {
                    self.showNoResultsFoundView()
                }
                
                return
            }
            
            self.calculateRating()
            
        }) { (error) in
            print("JugglerProfileVC/FetchReviews() Error: ", error)
            if self.currentHeaderButton == 2 {
                self.showNoResultsFoundView()
            }
        }
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
        
        if currentHeaderButton == 0 {
            if self.acceptedTasks.count >= indexPath.item {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CollectionViewCellIds.acceptedTaskCell, for: indexPath) as! AcceptedTaskCell
                
                let task = self.acceptedTasks[indexPath.item]
                
                // Match the correct task with the correct Juggler
                self.acceptedUsers.forEach { (key, value) in
                    for val in value {
                        if task.id == val {
                            cell.userId = key
                        }
                    }
                }
                
                cell.task = task
                cell.delegate = self
                cell.isCurrentUserJuggler = true
                
                return cell
            }
        } else if currentHeaderButton == 1 {
            if self.completedTasks.count >= indexPath.item {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CollectionViewCellIds.completedTaskCell, for: indexPath) as! CompletedTaskCell
                
                let task = self.completedTasks[indexPath.item]
                
                // Match the correct task with the correct Juggler
                self.completedUsers.forEach { (key, value) in
                    for val in value {
                        if task.id == val {
                            cell.userId = key
                        }
                    }
                }
                
                cell.task = task
                cell.delegate = self
                
                return cell
            }
        } else if currentHeaderButton == 2 {
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
        
        if self.currentHeaderButton == 2 {
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
        
        Database.isJugglerAccepted(userId: userId) { (jglr) in
            if let juggler = jglr {
                MainTabBarController.isJugglerAccepted = true
                DispatchQueue.main.async {
                    self.juggler = juggler
                    self.navigationItem.title = juggler.fullName
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
    
    func handleCompleteTaskButton(forTask task: Task?, userId: String?, completion: @escaping (Bool) -> Void) {
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { (_) in
            
            guard let task = task, let userId = userId, let jugglerId = Auth.auth().currentUser?.uid else {
                self.unableAlert()
                completion(false)
                return
            }
            
            if task.status != 1 {
                let alert = UIView.okayAlert(title: "Task Already Completed", message: "You or another Juggler have already completed this task.")
                self.present(alert, animated: true, completion: nil)
                completion(false)
                return
            }
            
            // Step 1: Remove reference in acceptedTasks for juggler
            let acceptedJugglerRef = Database.database().reference().child(Constants.FirebaseDatabase.acceptedTasks).child(jugglerId).child(userId).child(task.id)
            acceptedJugglerRef.removeValue(completionBlock: { (err, _) in
                if let error = err {
                    self.unableAlert()
                    completion(false)
                    print("Error completing task: \(error)")
                }
            })
            
            // Step 2: Remove reference in acceptedTasks for user
            let acceptedUserRef = Database.database().reference().child(Constants.FirebaseDatabase.acceptedTasks).child(userId).child(jugglerId).child(task.id)
            acceptedUserRef.removeValue(completionBlock: { (err, _) in
                if let error = err {
                    self.unableAlert()
                    completion(false)
                    print("Error completing task: \(error)")
                }
            })
            
            // Step 3: Update task to have status of 2 which means it has been completed
            let taskValues = [Constants.FirebaseDatabase.taskStatus : 2]
            let taskRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(task.userId).child(task.id)
            taskRef.updateChildValues(taskValues, withCompletionBlock: { (err, _) in
                
                if let error = err {
                    print("AcceptedTaskCellJugglerDelegate/handleCompleteTaskButton: \(error)")
                    self.unableAlert()
                    completion(false)
                    return
                }
            })
            
            // Step 4: Store a reference to task for juggler
            let completedJugglerRef = Database.database().reference().child(Constants.FirebaseDatabase.completedTasks).child(jugglerId).child(userId)
            completedJugglerRef.updateChildValues([task.id : 1], withCompletionBlock: { (err, _) in
                if let error = err {
                    print("AcceptedTaskCellJugglerDelegate/handleCompleteTaskButton: \(error)")
                    self.unableAlert()
                    completion(false)
                    return
                }
                
                // Step 5: Store a reference to task for user
                let completedUserRef = Database.database().reference().child(Constants.FirebaseDatabase.completedTasks).child(userId).child(jugglerId)
                completedUserRef.updateChildValues([task.id : 1], withCompletionBlock: { (err, _) in
                    if let error = err {
                        print("AcceptedTaskCellJugglerDelegate/handleCompleteTaskButton: \(error)")
                        self.unableAlert()
                        completion(false)
                        return
                    } else {
                        // Successfuly completed task
                        completion(true)
                        self.handleRefresh()
                        return
                    }
                })
            })
        }
        
        let alert = UIAlertController(title: "Task Completed?", message: "Are you sure? DO NOT TAP 'Yes' if you have not completed this task!", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(false)
        }
        alert.addAction(cancelAction)
        alert.addAction(yesAction)
        
        self.present(alert, animated: true, completion: nil)
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
