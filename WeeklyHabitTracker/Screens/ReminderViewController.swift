//
//  ReminderViewController.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/22/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import UIKit

class ReminderViewController: UIViewController {
    var delegate: SaveReminderDelegate?
    let reminderLabel = FormingPickerLabel(title: "9:00 AM")
    let toggle = UISwitch()
    let defaultLabel = UILabel()
    let picker = UIDatePicker()
    var reminder: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Reminder"
        
        configureToggle()
        configureDefaultLabel()
        configurePicker()
        configureConstraints()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            if toggle.isOn { reminder = getReminderAsString() }
            else { reminder = nil }
            delegate?.saveReminder(reminder: reminder)
        }
    }
    
    func configureToggle() {
        toggle.isOn = true
        toggle.addTarget(self, action: #selector(toggleTapped), for: .valueChanged)
    }
    
    func configureDefaultLabel() {
        defaultLabel.text = "The default reminder is a grouped notification at 9:00 AM for all habits ocurring that day. \n\nSetting a custom reminder will send a notification only for this habit at the set time."
        defaultLabel.numberOfLines = 0
        defaultLabel.sizeToFit()
        defaultLabel.textAlignment = .center
        defaultLabel.textColor = .secondaryLabel
        defaultLabel.font = UIFont.systemFont(ofSize: 17)
    }
    
    func configurePicker() {
        picker.datePickerMode = .time
        picker.minuteInterval = 5
        if let date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) {
            picker.date = date
        }
        picker.addTarget(self, action: #selector(pickerChanged), for: .valueChanged)
    }

    func configureConstraints() {
        let top = view.safeAreaLayoutGuide.topAnchor, left = view.leftAnchor, right = view.rightAnchor
        view.addSubview(reminderLabel)
        reminderLabel.anchor(top: top, left: left, bottom: nil, right: nil, paddingTop: 15, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: view.frame.width - 96, height: 40)
        view.addSubview(toggle)
        toggle.anchor(top: top, left: reminderLabel.rightAnchor, bottom: nil, right: right, paddingTop: 20, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        view.addSubview(picker)
        picker.anchor(top: reminderLabel.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: picker.frame.height)
        view.addSubview(defaultLabel)
        defaultLabel.anchor(top: picker.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: 15, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
    }
    
    @objc func toggleTapped(sender: UISwitch) {
        picker.isEnabled = !picker.isEnabled
        if !sender.isOn { reminderLabel.text = "No Reminder" }
        else { reminderLabel.text = getReminderAsString() }
    }
    
    @objc func pickerChanged() {
        if picker.isEnabled { reminderLabel.text = getReminderAsString() }
        else { reminderLabel.text = "No Reminder" }
    }
    
    func getReminderAsString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        let time = picker.date
        return formatter.string(from: time)
    }
}

protocol SaveReminderDelegate {
    func saveReminder(reminder: String?)
}