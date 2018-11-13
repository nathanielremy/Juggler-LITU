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
    var task: Task? {
        didSet {
            guard let task = task else {
                self.navigationController?.popViewController(animated: true)
                return
            }
            
            print("TASK: \(task)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red
        
    }
    
}
