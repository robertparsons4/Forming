//
//  FormingTitleLabel.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/15/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import UIKit

class FormingTitleLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    init(title: String) {
        super.init(frame: .zero)
        text = title
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        font = UIFont.boldSystemFont(ofSize: 20)
        textAlignment = .left
        textColor = .label
    }
    
}
