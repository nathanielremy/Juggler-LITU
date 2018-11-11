//
//  ApplicationStepsVC.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 11/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit

class ApplicationStepsVC: UIViewController {
    
    //MARK: Stored properties
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.mainBlue()
        label.text = "Steps to Become a Juggler"
        
        return label
    }()
    
    // Must be lazy var to add tapGestureRecognizer.
    lazy var stepOneLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: "1. ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.darkText])
        attributedText.append(NSAttributedString(string: "Make sure you have all ", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        attributedText.append(NSAttributedString(string: "Requirements", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()]))
        attributedText.append(NSAttributedString(string: ".", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        
        label.attributedText = attributedText
        
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleRequirements))
        label.addGestureRecognizer(tapGesture)
        
        return label
    }()
    
    @objc fileprivate func handleRequirements() {
        let signupRequirementsNavVC = UINavigationController(rootViewController: SignupRequirementsVC())
        present(signupRequirementsNavVC, animated: true, completion: nil)
    }
    
    let stepTwoLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: "2. ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.darkText])
        attributedText.append(NSAttributedString(string: "Continue and apply.", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        
        label.attributedText = attributedText
        
        return label
    }()
    
    let stepThreeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: "3. ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.darkText])
        attributedText.append(NSAttributedString(string: "Once we have recieved your application, we will email you a date, time, location and other specifications so that we can conduct your ", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        attributedText.append(NSAttributedString(string: "in-person interview", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.darkText]))
        attributedText.append(NSAttributedString(string: ".", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        
        label.attributedText = attributedText
        
        return label
    }()
    
    lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.mainBlue()
        button.setTitle("Continue", for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        
        return button
    }()
    
    @objc fileprivate func handleContinue() {
        let signupVC = SignupVC()
        navigationController?.pushViewController(signupVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        navigationItem.title = "Application Steps"
        
        setupViews()
    }
    
    fileprivate func setupViews() {
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 50, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: 30)
        
        view.addSubview(stepOneLabel)
        stepOneLabel.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 50, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: 50)
        
        view.addSubview(stepTwoLabel)
        anchorHelper(forView: stepTwoLabel, topAnchor: stepOneLabel.bottomAnchor, topPadding: 0, height: 50)
        
        view.addSubview(stepThreeLabel)
        anchorHelper(forView: stepThreeLabel, topAnchor: stepTwoLabel.bottomAnchor, topPadding: -8, height: 125)
        
        view.addSubview(continueButton)
        continueButton.anchor(top: stepThreeLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 50, paddingLeft: 45, paddingBottom: 0, paddingRight: -45, width: nil, height: 50)
        continueButton.layer.cornerRadius = 25
    }
    
    fileprivate func anchorHelper(forView anchorView: UIView, topAnchor: NSLayoutYAxisAnchor, topPadding: CGFloat, height: CGFloat) {
        return anchorView.anchor(top: topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: topPadding, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: height)
    }
}
