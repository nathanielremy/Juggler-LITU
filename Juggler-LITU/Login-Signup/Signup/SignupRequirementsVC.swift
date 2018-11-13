//
//  SignupRequirementsVC.swift
//  Juggler-LITU
//
//  Created by Nathaniel Remy on 10/11/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit

class SignupRequirementsVC: UIViewController {
    
    //MARK: Stored properties
    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .white
        
        return sv
    }()
    
    let firstRequirementLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: "• ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.darkText])
        attributedText.append(NSAttributedString(string: "Must be atleast ", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        attributedText.append(NSAttributedString(string: "18 years of age", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()]))
        attributedText.append(NSAttributedString(string: ".", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        
        label.attributedText = attributedText
        
        return label
    }()
    
    let secondRequirementLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: "• ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.darkText])
        attributedText.append(NSAttributedString(string: "Must live ", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        attributedText.append(NSAttributedString(string: "in Barcelona ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()]))
        attributedText.append(NSAttributedString(string: "or ", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        attributedText.append(NSAttributedString(string: "surrounding areas", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()]))
        attributedText.append(NSAttributedString(string: ".", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        
        label.attributedText = attributedText
        
        return label
    }()
    
    let thirdRequirementLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: "• ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.darkText])
        attributedText.append(NSAttributedString(string: "Must have a ", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        attributedText.append(NSAttributedString(string: "spanish bank account", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()]))
        attributedText.append(NSAttributedString(string: ".", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        
        label.attributedText = attributedText
        
        return label
    }()
    
    let fourthRequirementLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: "• ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.darkText])
        attributedText.append(NSAttributedString(string: "Must have ", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        attributedText.append(NSAttributedString(string: "an iPhone", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()]))
        attributedText.append(NSAttributedString(string: ".", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        
        label.attributedText = attributedText
        
        return label
    }()
    
    let fifthRequirementLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: "• ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.darkText])
        attributedText.append(NSAttributedString(string: "Must have ", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        attributedText.append(NSAttributedString(string: "a Valid Government Issued ID", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()]))
        attributedText.append(NSAttributedString(string: ".", attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.gray]))
        
        label.attributedText = attributedText
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        navigationItem.title = "Requirements"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.leftBarButtonItem?.tintColor = .darkText
        
        setupViews()
    }
    
    @objc fileprivate func handleCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func setupViews() {
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: nil)
        scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height)
        
        scrollView.addSubview(firstRequirementLabel)
        anchorHelper(forView: firstRequirementLabel, topAnchor: scrollView.topAnchor, topPadding: 50, height: 50)
        
        scrollView.addSubview(secondRequirementLabel)
        anchorHelper(forView: secondRequirementLabel, topAnchor: firstRequirementLabel.bottomAnchor, topPadding: 0, height: 50)
        
        scrollView.addSubview(thirdRequirementLabel)
        anchorHelper(forView: thirdRequirementLabel, topAnchor: secondRequirementLabel.bottomAnchor, topPadding: 0, height: 50)
        
        scrollView.addSubview(fourthRequirementLabel)
        anchorHelper(forView: fourthRequirementLabel, topAnchor: thirdRequirementLabel.bottomAnchor, topPadding: 0, height: 50)
        
        scrollView.addSubview(fifthRequirementLabel)
        anchorHelper(forView: fifthRequirementLabel, topAnchor: fourthRequirementLabel.bottomAnchor, topPadding: 0, height: 50)
    }
    
    fileprivate func anchorHelper(forView anchorView: UIView, topAnchor: NSLayoutYAxisAnchor, topPadding: CGFloat, height: CGFloat) {
        return anchorView.anchor(top: topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: topPadding, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: height)
    }
}
