//
//  FormingTableView.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/21/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import UIKit
import SwiftUI

class FormingTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    var priority: Int64
    var flag: Bool
    var reminder: Date?
    var tableDelegate: FormingTableViewDelegate?
    
    let priorities = [0: "None", 1: "1", 2: "2", 3: "3"]
    private let exclamationAttachment = NSTextAttachment()
    private let regularConfig = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 15, weight: .regular), scale: .default)
    
    let stepper = UIStepper()
    let flagSwitch = UISwitch()
    let haptics = UISelectionFeedbackGenerator()
    
    init(priority: Int64, reminder: Date?, flag: Bool) {
        self.priority = priority
        self.flag = flag
        self.reminder = reminder
        self.exclamationAttachment.image = UIImage(named: "exclamationmark", in: nil, with: regularConfig)
        self.exclamationAttachment.image = exclamationAttachment.image?.withTintColor(.secondaryLabel)
        super.init(frame: .zero, style: .plain)
        
        delegate = self
        dataSource = self
        register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        configureStepper()
        configureFlagSwitch()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RowNumbers.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let largeConfig = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 17), scale: .large)
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.imageView?.tintColor = .label
        switch indexPath.row {
        case RowNumbers.reminder.rawValue:
            cell.textLabel?.text = "Reminder"
            if let reminder = self.reminder { cell.detailTextLabel?.text = CalUtility.getTimeAsString(time: reminder) } else { cell.detailTextLabel?.text = "None" }
            cell.imageView?.image = UIImage(named: "clock", in: nil, with: largeConfig)
            cell.accessoryType = .disclosureIndicator
        case RowNumbers.goals.rawValue:
            cell.textLabel?.text = "Goals"
            cell.imageView?.image = UIImage(named: "star.circle", in: nil, with: largeConfig)
            cell.accessoryType = .disclosureIndicator
        case RowNumbers.priority.rawValue:
            cell.textLabel?.text = "Priority"
            cell.detailTextLabel?.attributedText = createExclamation(fromPriority: self.priority)
            cell.imageView?.image = UIImage(named: "exclamationmark.circle", in: nil, with: largeConfig)
            cell.accessoryView = stepper
            cell.selectionStyle = .none
        case RowNumbers.flag.rawValue:
            cell.textLabel?.text = "Flag"
            cell.imageView?.image = UIImage(named: "flag.circle", in: nil, with: largeConfig)
            cell.accessoryView = flagSwitch
            cell.selectionStyle = .none
        default: ()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case RowNumbers.reminder.rawValue:
            var reminderView: ReminderViewController
            if let reminder = self.reminder { reminderView = ReminderViewController(reminder: reminder) }
            else { reminderView = ReminderViewController(reminder: nil) }
            reminderView.updateDelegate = self
            if let parentView = tableView.findViewController() as? HabitDetailViewController { reminderView.saveDelegate = parentView.self }
            tableDelegate?.push(view: reminderView)
        case RowNumbers.goals.rawValue:
            tableDelegate?.push(view: GoalsViewController(weeklyGoal: 1, habitGoal: 1))
        default: ()
        }
        deselectRow(at: indexPath, animated: true)
    }
            
    func configureStepper() {
        stepper.minimumValue = 0
        stepper.maximumValue = 3
        stepper.value = Double(self.priority)
        stepper.addTarget(self, action: #selector(stepperTapped), for: .valueChanged)
    }
    
    func configureFlagSwitch() {
        flagSwitch.isOn = self.flag
        flagSwitch.addTarget(self, action: #selector(flagSwitchTapped), for: .valueChanged)
    }
    
    @objc func stepperTapped(sender: UIStepper) {
        haptics.selectionChanged()
        cellForRow(at: IndexPath(row: RowNumbers.priority.rawValue, section: 0))?.detailTextLabel?.attributedText = createExclamation(fromPriority: Int64(sender.value))
        tableDelegate?.save(priority: Int64(sender.value))
    }
    
    @objc func flagSwitchTapped(sender: UISwitch) {
        haptics.selectionChanged()
        tableDelegate?.save(flag: sender.isOn)
    }
    
    func createExclamation(fromPriority num: Int64) -> NSAttributedString {
        let attrString = NSMutableAttributedString()
        switch num {
        case 1:
            attrString.append(NSAttributedString(attachment: self.exclamationAttachment))
            attrString.append(NSAttributedString(string: "           "))
        case 2:
            attrString.append(NSAttributedString(attachment: self.exclamationAttachment))
            attrString.append(NSAttributedString(attachment: self.exclamationAttachment))
            attrString.append(NSAttributedString(string: "           "))
        case 3:
            attrString.append(NSAttributedString(attachment: self.exclamationAttachment))
            attrString.append(NSAttributedString(attachment: self.exclamationAttachment))
            attrString.append(NSAttributedString(attachment: self.exclamationAttachment))
            attrString.append(NSAttributedString(string: "           "))
        default:
            attrString.append(NSAttributedString(string: "None"))
        }
        return attrString
    }
}

protocol FormingTableViewDelegate {
    func push(view: UIViewController)
    func save(priority: Int64)
    func save(flag: Bool)
}

extension FormingTableView: UpdateReminderDelegate {
    func update(reminder: Date?) {
        let cell = self.cellForRow(at: IndexPath(row: RowNumbers.reminder.rawValue, section: 0))
        if let unwrappedReminder = reminder {
            self.reminder = unwrappedReminder
            cell?.detailTextLabel?.text = CalUtility.getTimeAsString(time: unwrappedReminder)
        }
        else {
            self.reminder = nil
            cell?.detailTextLabel?.text = "None"
        }
    }
}

enum RowNumbers: Int, CaseIterable {
    case goals, reminder, priority, flag
}
