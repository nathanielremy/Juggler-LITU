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
    
    var rating: Double?
    var reviews = [Review]()
    var tempReviews = [Review]()
    
    var acceptedTasks = [Task]()
    var tempAcceptedTasks = [Task]()
    
    var completedTasks = [Task]()
    var tempCompletedTasks = [Task]()
    
    // currentHeaderButton values
    // 0 == acceptedButton
    // 1 == completedButton
    // 2 == reviewsButton
    var currentHeaderButton = 0
    var canFetchTasks = true
    
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
        
        self.setupActivityIndicator()
        self.animateAndShowActivityIndicator(true)
        
        guard let jugglerId = Auth.auth().currentUser?.uid else { fatalError() }
        self.fetchJuggler(forUserID: jugglerId)
        self.fetchJuggerTasks(forJugglerId: jugglerId)
        self.fetchReviews(forJugglerId: jugglerId)
    }
    
    fileprivate func setupActivityIndicator() {
        view.addSubview(self.activityIndicator)
        self.activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    // Re-fetch data when collection view is refreshed.
    @objc fileprivate func handleRefresh() {
        guard let jugglerId = Auth.auth().currentUser?.uid else { fatalError("No jugglerId") }
        fetchJuggler(forUserID: jugglerId)
        
        if canFetchTasks && self.currentHeaderButton != 2 {
            //Empty all temp arrays to allow new values to be stored
            self.tempAcceptedTasks.removeAll()
            self.tempCompletedTasks.removeAll()
            
            self.fetchJuggerTasks(forJugglerId: jugglerId)
        } else if self.currentHeaderButton == 2 {
            //Empty all temp arrays to allow new values to be stored
            self.tempReviews.removeAll()
            
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
    
    fileprivate func fetchJuggler(forUserID userID: String) {
        Database.fetchJuggler(userID: userID) { (usr) in
            if let juggler = usr, juggler.isJuggler {
                self.juggler = juggler
                self.navigationItem.title = juggler.firstName + " " + juggler.lastName
            }
        }
    }
    
    // Retrieve tasks related to juggler
    fileprivate func fetchJuggerTasks(forJugglerId jugglerId: String) {
        if !canFetchTasks {
            return
        }
        
        self.canFetchTasks = false
        
        let tasksRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).queryOrdered(byChild: Constants.FirebaseDatabase.mutuallyAcceptedBy).queryEqual(toValue: jugglerId)
        tasksRef.observeSingleEvent(of: .value, with: { (tasksSnapshot) in
            
            guard let snapshotDictionary = tasksSnapshot.value as? [String : [String : Any]] else {
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
                if task.status == 1 { // Accepted
                    self.tempAcceptedTasks.append(task)
                } else if task.status == 2 { // Completed
                    self.tempCompletedTasks.append(task)
                }
                
                // Re-arrange all task arrays from youngest to oldest
                self.tempAcceptedTasks.sort(by: { (task1, task2) -> Bool in
                    return task1.creationDate.compare(task2.creationDate) == .orderedDescending
                })
                self.tempCompletedTasks.sort(by: { (task1, task2) -> Bool in
                    return task1.completionDate.compare(task2.completionDate) == .orderedDescending
                })
                
                if tasksCreated == snapshotDictionary.count {
                    self.acceptedTasks = self.tempAcceptedTasks
                    self.completedTasks = self.tempCompletedTasks
                    self.removeNoResultsView()
                    self.canFetchTasks = true
                    self.animateAndShowActivityIndicator(false)
                    return
                }
            }
        }) { (error) in
            self.acceptedTasks.removeAll()
            self.completedTasks.removeAll()
            self.showNoResultsFoundView(andReload: true)
            self.animateAndShowActivityIndicator(false)
            self.canFetchTasks = true
            print("Error fetching jugglerTasksRef: \(error)")
        }
    }
    
    fileprivate func fetchReviews(forJugglerId jugglerId: String) {
        let reviewsRef = Database.database().reference().child(Constants.FirebaseDatabase.reviewsRef).child(jugglerId)
        reviewsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let snapshotDictionary = snapshot.value as? [String : [String : Any]] else {
                self.reviews.removeAll()
                self.rating = 0
                if self.currentHeaderButton == 2 {
                    self.showNoResultsFoundView(andReload: true)
                }
                self.animateAndShowActivityIndicator(false)
                return
            }
            
            var reviewsCreated = 0
            snapshotDictionary.forEach { (key, reviewDictionary) in
                let review = Review(id: key, dictionary: reviewDictionary)
                reviewsCreated += 1
                
                self.tempReviews.append(review)
                
                // Re-arrange reviews arrays from youngest to oldest
                self.tempReviews.sort(by: { (task1, task2) -> Bool in
                    return task1.creationDate.compare(task2.creationDate) == .orderedDescending
                })
                
                if reviewsCreated == snapshotDictionary.count {
                    self.reviews = self.tempReviews
                    self.calculateRating()
                }
            }
        }) { (error) in
            self.reviews.removeAll()
            self.rating = 0
            if self.currentHeaderButton == 2 {
                self.showNoResultsFoundView(andReload: true)
            }
            self.animateAndShowActivityIndicator(false)
            print("JugglerProfileVC fetching reviews error: \(error)")
        }
    }
    
    func calculateRating() {
        var totalStars: Double = 0
        
        for review in self.reviews {
            totalStars += Double(review.intRating)
        }
        
        let outOfFive = Double(totalStars/Double(reviews.count))
        self.rating = outOfFive
        
        if self.canFetchTasks || self.currentHeaderButton == 2 {
            self.removeNoResultsView()
            self.animateAndShowActivityIndicator(false)
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
                self.showNoResultsFoundView(andReload: false)
                return 0
            } else {
                return self.acceptedTasks.count
            }
        } else if currentHeaderButton == 1 {
            if self.completedTasks.count == 0 {
                self.showNoResultsFoundView(andReload: false)
                return 0
            } else {
                return self.completedTasks.count
            }
        } else if currentHeaderButton == 2 {
            if self.reviews.count == 0 {
                self.showNoResultsFoundView(andReload: false)
                return 0
            } else {
                return self.reviews.count
            }
        }
        
        self.showNoResultsFoundView(andReload: false)
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
                
                let task = self.acceptedTasks[indexPath.item]
                
                cell.acceptedTaskArrayIndex = indexPath.item
                cell.userId = task.userId
                cell.task = task
                cell.delegate = self

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
        self.noResultsView.removeFromSuperview()
        
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
    
    func handleCompleteTaskButton(forTask task: Task?, userId: String?, acceptedTaskArrayIndex: Int?, completion: @escaping (Bool, Bool) -> Void) {
        guard let task = task, let currentuserID = Auth.auth().currentUser?.uid else {
            completion(false, false); return
        }
        
        if task.isTaskDenied {
            let alert = UIView.okayAlert(title: "Task Denied", message: "We are reviewing what happened and will be in contact with you shortly.")
            self.present(alert, animated: true, completion: nil)
            completion(false, true)
            return
        }
        
        if task.isJugglerComplete {
            explainCompletionProcess()
            completion(true, false)
            return
        }
        
        let completeAction = UIAlertAction(title: "Complete", style: .default) { (_) in
            if currentuserID != task.mutuallyAcceptedBy {
                completion(false, false); return
            }
            
            let taskRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(task.id)
            taskRef.updateChildValues([Constants.FirebaseDatabase.isJugglerComplete : 1]) { (err, _) in
                if let error = err {
                    print("ERROR COMPLETING TASK: \(error)")
                    completion(false, false)
                    return
                }
                
                if let acceptedTaskArrayIndex = acceptedTaskArrayIndex {
                    self.acceptedTasks[acceptedTaskArrayIndex].isJugglerComplete = true
                }
                
                completion(true, false)
                self.explainCompletionProcess()
            }
        }
        
        let alert = UIAlertController(title: "Task Completed?", message: "Are you sure? DO NOT TAP 'Complete' if you have not completed this task!", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(false, task.isTaskDenied)
        }
        alert.addAction(cancelAction)
        alert.addAction(completeAction)
        
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
