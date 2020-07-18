//
//  ReminderViewController.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/22/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import UIKit

class ReminderViewController: UIViewController {
    private var updateDelegate: UpdateReminderDelegate?
    private var saveDelegate: SaveReminderDelegate?
    private var reminderDate: Date?

    private let reminderLabel = FormingPickerLabel()
    private let toggle = UISwitch()
    private let explanationLabel = FormingSecondaryLabel(text: "Set a time to be reminded at on days this habit is supposed to be completed.")
    private let picker = UIDatePicker()
    
    init(reminder: Date?) {
        super.init(nibName: nil, bundle: nil)
        self.reminderDate = reminder
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Reminder"

        if self.reminderDate != nil {
            reminderLabel.text = CalUtility.getTimeAsString(time: self.reminderDate!)
        } else {
            reminderLabel.text = "No Reminder"
        }
        configureToggle()
        configurePicker()
        configureConstraints()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            if toggle.isOn { self.reminderDate = picker.date }
            else { self.reminderDate = nil }
            updateDelegate?.update(reminder: self.reminderDate)
            saveDelegate?.save(reminder: self.reminderDate)
        }
    }
    
    func setUpdateDelegate(delegate: UpdateReminderDelegate) {
        self.updateDelegate = delegate
    }
    
    func setSaveDelegate(delegate: SaveReminderDelegate) {
        self.saveDelegate = delegate
    }
    
    func configureToggle() {
        if self.reminderDate != nil {
            toggle.isOn = true
        } else {
            toggle.isOn = false
        }
        
        toggle.addTarget(self, action: #selector(toggleTapped), for: .valueChanged)
    }
    
    func configurePicker() {
        picker.datePickerMode = .time
        picker.minuteInterval = 5
        if let reminder = self.reminderDate { picker.date = reminder }
        else {
            if let date = CalUtility.getTimeAsDate(time: "9:00 AM") { picker.date = date }
            picker.isEnabled = false
        }
        picker.addTarget(self, action: #selector(pickerChanged), for: .valueChanged)
    }

    func configureConstraints() {
        let top = view.safeAreaLayoutGuide.topAnchor, left = view.leftAnchor, right = view.rightAnchor
        view.addSubview(reminderLabel)
        reminderLabel.anchor(top: top, left: left, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: view.frame.width - toggle.frame.width - 60, height: 40)
        view.addSubview(toggle)
        toggle.anchor(top: top, left: reminderLabel.rightAnchor, bottom: nil, right: right, paddingTop: 25, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        view.addSubview(picker)
        picker.anchor(top: reminderLabel.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: picker.frame.height)
        view.addSubview(explanationLabel)
        explanationLabel.anchor(top: picker.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: 15, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
    }
    
    @objc func toggleTapped(sender: UISwitch) {
        if sender.isOn {
            picker.isEnabled = true
            reminderLabel.text = CalUtility.getTimeAsString(time: picker.date)
        } else {
            picker.isEnabled = false
            reminderLabel.text = "No Reminder"
        }
    }
    
    @objc func pickerChanged() {
        if picker.isEnabled { reminderLabel.text = CalUtility.getTimeAsString(time: picker.date) }
        else { reminderLabel.text = "No Reminder" }
    }
}

protocol UpdateReminderDelegate {
    func update(reminder: Date?)
}

protocol SaveReminderDelegate {
    func save(reminder: Date?)
}
