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
    private var goal: Int64?
    private var priority: Int64
    private var flag: Bool
    private var reminder: Date?
    private var tableDelegate: FormingTableViewDelegate?
    
    private let priorities = [0: "None", 1: "1", 2: "2", 3: "3"]
    private let exclamationAttachment = NSTextAttachment()
    private let regularConfig = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 15, weight: .regular), scale: .default)
    private let largeConfig = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 17), scale: .large)
    
    private let stepper = UIStepper()
    private let flagSwitch = UISwitch()
    private let haptics = UISelectionFeedbackGenerator()
    
    init(goal: Int64?, priority: Int64, reminder: Date?, flag: Bool) {
        self.goal = goal
        self.priority = priority
        self.flag = flag
        self.reminder = reminder
        self.exclamationAttachment.image = UIImage(named: "exclamationmark", in: nil, with: regularConfig)
        self.exclamationAttachment.image = exclamationAttachment.image?.withTintColor(.secondaryLabel)
        super.init(frame: .zero, style: .insetGrouped)
        
        delegate = self
        dataSource = self
        register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        configureStepper()
        configureFlagSwitch()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(delegate: FormingTableViewDelegate) {
        self.tableDelegate = delegate
    }
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return SectionNumber.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SectionNumber.firstSection.rawValue: return FirstSection.allCases.count
        case SectionNumber.secondSection.rawValue: return SecondSection.allCases.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return " "
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 20 : 5
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.imageView?.tintColor = .label
        switch indexPath.section {
        case SectionNumber.firstSection.rawValue:
            switch indexPath.row {
            case FirstSection.goal.rawValue:
                cell.textLabel?.text = "Goal"
                cell.imageView?.image = UIImage(named: "star.circle", in: nil, with: self.largeConfig)
                cell.detailTextLabel?.text = "Never-ending"
                cell.accessoryType = .disclosureIndicator
            case FirstSection.automaticTracking.rawValue:
                cell.textLabel?.text = "Automatic Tracking"
                cell.imageView?.image = UIImage(named: "xmark.circle", in: nil, with: self.largeConfig)
                cell.detailTextLabel?.text = "On"
                cell.accessoryType = .disclosureIndicator
            default: ()
            }
        case SectionNumber.secondSection.rawValue:
            switch indexPath.row {
            case SecondSection.reminder.rawValue:
                cell.textLabel?.text = "Reminder"
                if let reminder = self.reminder { cell.detailTextLabel?.text = CalUtility.getTimeAsString(time: reminder) }
                else { cell.detailTextLabel?.text = "None" }
                cell.imageView?.image = UIImage(named: "clock", in: nil, with: self.largeConfig)
                cell.accessoryType = .disclosureIndicator
            case SecondSection.priority.rawValue:
                cell.textLabel?.text = "Priority"
                cell.detailTextLabel?.attributedText = createExclamation(fromPriority: self.priority)
                cell.imageView?.image = UIImage(named: "exclamationmark.circle", in: nil, with: self.largeConfig)
                cell.accessoryView = stepper
                cell.selectionStyle = .none
            case SecondSection.flag.rawValue:
                cell.textLabel?.text = "Flag"
                cell.imageView?.image = UIImage(named: "flag.circle", in: nil, with: self.largeConfig)
                cell.accessoryView = flagSwitch
                cell.selectionStyle = .none
            default: ()
            }
        default: ()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case SectionNumber.firstSection.rawValue:
            switch indexPath.row {
            case FirstSection.goal.rawValue:
                let goalView = GoalViewController(goal: 0)
                goalView.setUpdateDelegate(delegate: self)
                if let parentView = tableView.findViewController() as? HabitDetailViewController {
                    goalView.setSaveDelegate(delegate: parentView.self)
                }
                tableDelegate?.push(view: goalView)
            case FirstSection.automaticTracking.rawValue: print("tracking")
            default: ()
            }
        case SectionNumber.secondSection.rawValue:
            if indexPath.row == SecondSection.reminder.rawValue {
                let reminderView = ReminderViewController(reminder: self.reminder)
                reminderView.setUpdateDelegate(delegate: self)
                if let parentView = tableView.findViewController() as? HabitDetailViewController {
                    reminderView.setSaveDelegate(delegate: parentView.self)
                }
                tableDelegate?.push(view: reminderView)
            }
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
        cellForRow(at: IndexPath(row: SecondSection.priority.rawValue, section: SectionNumber.secondSection.rawValue))?.detailTextLabel?.attributedText = createExclamation(fromPriority: Int64(sender.value))
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

extension FormingTableView: UpdateGoalDelegate {
    func update(goal: Int64?) {
        self.goal = goal
        
        let cell = cellForRow(at: IndexPath(row: FirstSection.goal.rawValue, section: SectionNumber.firstSection.rawValue))
        if let goal = self.goal {
            cell?.detailTextLabel?.text = "\(goal)"
        } else {
            cell?.detailTextLabel?.text = "Never-ending"
        }
    }
}

extension FormingTableView: UpdateReminderDelegate {
    func update(reminder: Date?) {
        self.reminder = reminder

        let cell = cellForRow(at: IndexPath(row: SecondSection.reminder.rawValue, section: SectionNumber.secondSection.rawValue))
        if let reminder = self.reminder {
            cell?.detailTextLabel?.text = CalUtility.getTimeAsString(time: reminder)
        } else {
            cell?.detailTextLabel?.text = "None"
        }
    }
}

//enum SectionNumber: Int, CaseIterable {
//    case firstSection, secondSection
//}
//
//enum FirstSection: Int, CaseIterable {
//    case goal, automaticTracking
//}
//
//enum SecondSection: Int, CaseIterable {
//    case reminder, priority, flag
//}
