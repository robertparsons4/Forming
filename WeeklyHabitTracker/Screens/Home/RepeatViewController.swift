//
//  RepeatViewController.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/22/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import UIKit

class RepeatViewController: UIViewController {
    var updateDelegate: UpdateRepeatDelegate?
    var saveDelegate: SaveRepeatDelegate?
    var repeatability: Int64
    let pickerData: [Int: String]
    
    let repeatLabel = FormingPickerLabel()
    let defaultLabel = UILabel()
    let picker = UIPickerView()
    
    init(repeatability: Int64, data: [Int: String]) {
        print(repeatability)
        self.repeatability = repeatability
        self.pickerData = data
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Repeat"
        
        repeatLabel.text = pickerData[Int(self.repeatability)]
        configureDefaultLabel()
        configurePicker()
        configureConstraints()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            updateDelegate?.updateRepeat(repeatability: self.repeatability)
            saveDelegate?.saveRepeat(repeatability: self.repeatability)
        }
    }
    
    func configureDefaultLabel() {
        defaultLabel.text = "The default behavior for a reminder is to repeat every week until it is deleted. Setting a custom repeat will repeat the habit every x weeks."
        defaultLabel.numberOfLines = 0
        defaultLabel.sizeToFit()
        defaultLabel.textAlignment = .center
        defaultLabel.textColor = .secondaryLabel
        defaultLabel.font = UIFont.systemFont(ofSize: 17)
    }
    
    func configurePicker() {
        picker.dataSource = self
        picker.delegate = self
        picker.selectRow(Int(self.repeatability), inComponent: 0, animated: false)
    }
    
    func configureConstraints() {
        let top = view.safeAreaLayoutGuide.topAnchor, left = view.leftAnchor, right = view.rightAnchor
        view.addSubview(repeatLabel)
        repeatLabel.anchor(top: top, left: left, bottom: nil, right: right, paddingTop: 15, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 40)
        view.addSubview(picker)
        picker.anchor(top: repeatLabel.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: picker.frame.height)
        view.addSubview(defaultLabel)
        defaultLabel.anchor(top: picker.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: 15, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
    }

}

extension RepeatViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        repeatLabel.text = pickerData[row]
        repeatability = Int64(row)
    }
}

protocol UpdateRepeatDelegate {
    func updateRepeat(repeatability: Int64)
}

protocol SaveRepeatDelegate {
    func saveRepeat(repeatability: Int64)
}