//
//  NewHabitViewController.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/15/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import UIKit
import UserNotifications

class HabitDetailViewController: UIViewController {
    var habitDelegate: SaveHabitDelegate?
    private let persistenceManager: PersistenceService
    private let center: UNUserNotificationCenter
    
    var editMode = false
    var habit: Habit? {
        didSet {
            editMode = true
            if let title = habit?.title { titleTextField.text = title }
            if let days = habit?.days { dayFlags = days }
            if let color = habit?.color {
                selectedColor = Int(color)
                colorFlags[Int(color)] = true
            }
            if let priority = habit?.priority { self.priority = priority }
            if let flag = habit?.flag { self.flag = flag }
            if let reminder = habit?.reminder { self.reminder = reminder } else { self.reminder = nil }
        }
    }
    
    let scrollView = UIScrollView()
    let titleLabel = FormingTitleLabel(title: "Title:")
    let colorLabel = FormingTitleLabel(title: "Color:")
    let daysLabel = FormingTitleLabel(title: "Days:")
    let titleTextField = FormingTextField(placeholder: "Example: Run 1 Mile" , returnKeyType: .done)
    
    let topColors = [FormingColors.getColor(fromValue: 0), FormingColors.getColor(fromValue: 1), FormingColors.getColor(fromValue: 2), FormingColors.getColor(fromValue: 3), FormingColors.getColor(fromValue: 4)]
    let bottomColors = [FormingColors.getColor(fromValue: 5), FormingColors.getColor(fromValue: 6), FormingColors.getColor(fromValue: 7), FormingColors.getColor(fromValue: 8), FormingColors.getColor(fromValue: 9)]
    let topColorsStackView = UIStackView()
    let bottomColorsStackView = UIStackView()
    var colorFlags = [false, false, false, false, false, false, false, false, false, false]
    var selectedColor: Int? = nil
    
    let days = ["Su", "M", "T", "W", "Th", "F", "Sa"]
    var dayFlags = [false, false, false, false, false, false, false]
    let daysStackView = UIStackView()
    var dayStatuses = [Status]()
        
    var formingTableView: FormingTableView?
    var priority: Int64 = 0
    var flag: Bool = false
    var reminder: Date? = CalUtility.getTimeAsDate(time: "9:00 AM")
    
    let haptics = UISelectionFeedbackGenerator()
    
    // MARK: - Initializers
    init(persistenceManager: PersistenceService, notificationCenter: UNUserNotificationCenter) {
        self.persistenceManager = persistenceManager
        self.center = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ViewController Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = editMode ? "Edit Habit" : "New Habit"
        titleTextField.delegate = self
        formingTableView = FormingTableView(priority: self.priority, reminder: self.reminder, flag: self.flag)
        formingTableView?.tableDelegate = self
        
        configureScrollView()
        configureStackView(topColorsStackView, withArray: topColors)
        configureStackView(bottomColorsStackView, withArray: bottomColors)
        configureStackView(daysStackView, withArray: days)
        configureConstraints()
        
        if !editMode {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveButtonTapped))
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        } else {
            let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveButtonTapped))
            let deleteButton = UIBarButtonItem(title: "Delete", style: .done, target: self, action: #selector(deleteButtonTapped))
            deleteButton.tintColor = .systemRed
            navigationItem.rightBarButtonItems = [saveButton, deleteButton]
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        }
    }
    
    // MARK: - Configuration Functions
    func configureScrollView() {
        scrollView.backgroundColor = .systemBackground
        scrollView.alwaysBounceVertical = true
    }
    
    func configureStackView(_ stackView : UIStackView, withArray items: [Any]) {
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        
        if items as? [String] == days {
            stackView.spacing = (view.frame.width - 30 - 280) / 6
            let heavyAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .heavy)]
            let thinAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .thin)]
            for (index, item) in items.enumerated() {
                guard let day = item as? String else { return }
                let button = FormingDayButton(title: day, tag: index, width: 40)
                button.setAttributedTitle(NSAttributedString(string: day, attributes: thinAttribute), for: .normal)
                button.setAttributedTitle(NSAttributedString(string: day, attributes: heavyAttribute), for: .selected)
                button.setBackgroundColor(color: .systemFill, forState: .selected)
                button.addTarget(self, action: #selector(dayButtonTapped), for: .touchUpInside)
                if dayFlags[index] { button.isSelected = true }
                stackView.addArrangedSubview(button)
            }
        } else {
            var tagCounter = 0
            stackView.spacing = (view.frame.width - 80 - 200) / 4
            let config = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 17, weight: .heavy))
            for (index, item) in items.enumerated() {
                guard let color = item as? UIColor else { return }
                if stackView == bottomColorsStackView && index == 0 { tagCounter = 5 }
                let button = FormingColorButton(color: color, tag: tagCounter, width: 40)
                button.setImage(UIImage(named: "checkmark", in: nil, with: config), for: .selected)
                button.addTarget(self, action: #selector(colorButtonTapped), for: .touchUpInside)
                if let color = selectedColor { if tagCounter == color { button.isSelected = true } }
                stackView.addArrangedSubview(button)
                tagCounter += 1
            }
        }
    }
    
    func configureConstraints() {
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let top = scrollView.topAnchor, left = scrollView.leftAnchor, right = scrollView.rightAnchor
        let labelHeight: CGFloat = 25, viewHeight: CGFloat = 40, outterPad: CGFloat = 15, innerPad: CGFloat = 5
        let viewWidth = view.frame.width - 30
        
        scrollView.addSubview(titleLabel)
        titleLabel.anchor(top: top, left: left, bottom: nil, right: right, paddingTop: outterPad, paddingLeft: outterPad, paddingBottom: 0, paddingRight: outterPad, width: 0, height: labelHeight)
        scrollView.addSubview(titleTextField)
        titleTextField.anchor(top: titleLabel.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: innerPad, paddingLeft: outterPad, paddingBottom: 0, paddingRight: outterPad, width: viewWidth, height: viewHeight)
        
        scrollView.addSubview(daysLabel)
        daysLabel.anchor(top: titleTextField.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: outterPad, paddingLeft: outterPad, paddingBottom: 0, paddingRight: outterPad, width: 0, height: labelHeight)
        scrollView.addSubview(daysStackView)
        daysStackView.anchor(top: daysLabel.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: innerPad, paddingLeft: outterPad, paddingBottom: 0, paddingRight: outterPad, width: viewWidth, height: viewHeight)

        scrollView.addSubview(colorLabel)
        colorLabel.anchor(top: daysStackView.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: outterPad, paddingLeft: outterPad, paddingBottom: 0, paddingRight: outterPad, width: 0, height: labelHeight)
        scrollView.addSubview(topColorsStackView)
        topColorsStackView.anchor(top: colorLabel.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: innerPad, paddingLeft: outterPad + 25, paddingBottom: 0, paddingRight: outterPad + 25, width: viewWidth - 50, height: viewHeight)
        scrollView.addSubview(bottomColorsStackView)
        bottomColorsStackView.anchor(top: topColorsStackView.bottomAnchor, left: left, bottom: nil, right: right, paddingTop: innerPad + 5, paddingLeft: outterPad + 25, paddingBottom: 0, paddingRight: outterPad + 25, width: viewWidth - 50, height: viewHeight)
        
        if let tableView = formingTableView {
            scrollView.addSubview(tableView)
            tableView.anchor(top: bottomColorsStackView.bottomAnchor, left: left, bottom: scrollView.bottomAnchor, right: right, paddingTop: outterPad * 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: viewWidth + 30, height: 132)
        }
    }
    
    // MARK: - Functions
    func createNotificationRequest(withTitle title: String, andTime time: Date, andIndex index: Int, andID id: String) -> UNNotificationRequest{
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder: \(title)"
        content.body = "You have a \(CalUtility.getTimeAsString(time: time)) daily reminder set for this habit."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "alarm"
        content.userInfo = ["customData": id]
        let trigger = UNCalendarNotificationTrigger(dateMatching: CalUtility.getReminderComps(time: time, weekday: index + 1), repeats: true)
        return UNNotificationRequest(identifier: "\(id)-\(String(index))", content: content, trigger: trigger)
    }
    
    func deleteNotificationRequests(fromID id: String, andDays days: [Bool]) {
        var identifiers = [String]()
        for (index, day) in days.enumerated() {
            if day { identifiers.append("\(id)-\(String(index))") }
        }
        self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
        self.center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    // MARK: - Selectors
    @objc func saveButtonTapped() {
        if !dayFlags.contains(true) || !colorFlags.contains(true) {
            let alert = UIAlertController(title: "Incomplete Habit", message: "Please ensure that you have a color and at least one day selected.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default))
            present(alert, animated: true)
            return
        }
        
        DispatchQueue.main.async { self.dismiss(animated: true) }
        
        if !editMode {
            let initialHabit = Habit(context: persistenceManager.context)
            initialHabit.title = titleTextField.text?.trimmingCharacters(in: .whitespaces)
            initialHabit.days = dayFlags
            if let color = colorFlags.firstIndex(of: true) { initialHabit.color = Int64(color) }
            dayFlags.forEach {
                if $0 { dayStatuses.append(.incomplete) }
                else { dayStatuses.append(.empty) }
            }
            initialHabit.statuses = dayStatuses
            initialHabit.priority = self.priority
            initialHabit.reminder = self.reminder
            initialHabit.flag = self.flag
            initialHabit.dateCreated = CalUtility.getCurrentDate()
            initialHabit.buttonState = false
            initialHabit.uniqueID = UUID().uuidString
            
            let initialArchive = Archive(context: persistenceManager.context)
            initialArchive.title = initialHabit.title ?? "Error"
            initialArchive.color = initialHabit.color
            initialArchive.habit = initialHabit
            initialArchive.active = true
            initialArchive.successRate = 100.0
            initialArchive.completedTotal = 0
            initialArchive.failedTotal = 0
            initialArchive.incompleteTotal = Int64(initialHabit.days.filter({ $0 == true }).count)
            
            let archivedHabit = ArchivedHabit(context: persistenceManager.context)
            initialArchive.createNewArchivedHabit(fromArchivedHabit: archivedHabit, withStatuses: initialHabit.statuses)
            
            initialHabit.archive = initialArchive
            
            if let reminder = initialHabit.reminder, let title = initialHabit.title {
                for (index, day) in initialHabit.days.enumerated() {
                    if day {
                        self.center.add(createNotificationRequest(withTitle: title, andTime: reminder, andIndex: index, andID: initialHabit.uniqueID))
                    }
                }
            }
        } else {
            habit?.title = titleTextField.text?.trimmingCharacters(in: .whitespaces)
            if let color = colorFlags.firstIndex(of: true) { habit?.color = Int64(color) }
            if self.dayFlags[CalUtility.getCurrentDay()] != habit?.days[CalUtility.getCurrentDay()] {
                if self.dayFlags[CalUtility.getCurrentDay()] { habit?.buttonState = false }
            }
            
            if self.reminder == nil {
                if let id = habit?.uniqueID, let days = habit?.days { deleteNotificationRequests(fromID: id, andDays: days) }
            } else if (self.reminder != habit?.reminder) || (self.dayFlags != habit?.days ) {
                if let reminder = self.reminder, let title = habit?.title, let id = habit?.uniqueID, let days = habit?.days {
                    deleteNotificationRequests(fromID: id, andDays: days)
                    for (index, day) in self.dayFlags.enumerated() {
                        if day {
                            self.center.add(createNotificationRequest(withTitle: title, andTime: reminder, andIndex: index, andID: id))
                        }
                    }
                }
            }
            
            if habit?.days != dayFlags {
                for (index, day) in dayFlags.enumerated() {
                    if day {
                        switch habit?.statuses[index] {
                        case .completed: dayStatuses.append(.completed)
                        case .failed: dayStatuses.append(.failed)
                        case .incomplete: dayStatuses.append(.incomplete)
                        case .empty: dayStatuses.append(.incomplete)
                        default: ()
                        }
                    } else { dayStatuses.append(.empty) }
                }
                
                for (oldStatus, newStatus) in zip(habit!.statuses, self.dayStatuses) {
                    self.habit?.archive.updateStats(fromStatus: oldStatus, toStatus: newStatus)
                }
                
                habit?.days = dayFlags
                habit?.statuses = dayStatuses
                habit?.archive.updateCurrentArchivedHabit(withStatuses: dayStatuses)
            }
            habit?.priority = self.priority
            habit?.reminder = self.reminder
            habit?.flag = self.flag
            if let updatedHabit = habit {
                habit?.archive.title = updatedHabit.title ?? "Title Error"
                habit?.archive.color = updatedHabit.color
                habit?.archive.habit = updatedHabit
            }
        }
        
        persistenceManager.save()
        habitDelegate?.saveHabit()
    }
    
    @objc func deleteButtonTapped() {
        DispatchQueue.main.async {
            let deleteVC = UIAlertController(title: "Are you sure you want to delete this habit?", message: nil, preferredStyle: .actionSheet)
            deleteVC.view.tintColor = .systemGreen
            deleteVC.addAction(UIAlertAction(title: "Delete Habit", style: .default) { [weak self] _ in
                guard let self = self else { return }
                if let habitToDelete = self.habit {
                    self.deleteNotificationRequests(fromID: habitToDelete.uniqueID, andDays: habitToDelete.days)
                    habitToDelete.archive.active = false
                    self.habitDelegate?.delete(habit: habitToDelete)
                    self.dismiss(animated: true)
                }
            })
            deleteVC.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(deleteVC, animated: true)
        }
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc func colorButtonTapped(sender: UIButton) {
        let tag = sender.tag
        if sender.isSelected == true { sender.isSelected = false }
        else {
            if colorFlags.contains(true) {
                if let index = colorFlags.firstIndex(of: true) {
                    if index < 5 {
                        let button = topColorsStackView.arrangedSubviews[index] as? UIButton
                        button?.isSelected = false
                    } else {
                        let button = bottomColorsStackView.arrangedSubviews[index - 5] as? UIButton
                        button?.isSelected = false
                    }
                    colorFlags[index] = false
                }
            }
            colorFlags[tag] = true
            haptics.selectionChanged()
            sender.isSelected = true
        }
    }
    
    @objc func dayButtonTapped(sender: UIButton) {
        haptics.selectionChanged()
        let tag = sender.tag
        if sender.isSelected == true {
            sender.isSelected = false
            dayFlags[tag] = false
        } else {
            sender.isSelected = true
            dayFlags[tag] = true
        }
    }
}

// MARK: - Delegates
extension HabitDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}

extension HabitDetailViewController: FormingTableViewDelegate, SaveReminderDelegate {
    func pushViewController(view: UIViewController) {
        navigationController?.pushViewController(view, animated: true)
    }
    
    func savePriority(priority: Int64) {
        self.priority = priority
    }
    
    func saveFlag(flag: Bool) {
        self.flag = flag
    }
    
    func saveReminder(reminder: Date?) {
        self.reminder = reminder
    }
}

// MARK: - Protocols
protocol SaveHabitDelegate  {
    func saveHabit()
    func delete(habit: Habit)
}
