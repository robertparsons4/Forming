//
//  HomeCollectionViewController.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/14/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

private let reuseIdentifier = "homeHabitCell"
private let headerReuseIdentifier = "homeHeaderCell"

class HomeVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    private var habits = [Habit]()
    private let persistenceManager: PersistenceService
    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let userNotificationCenter: UNUserNotificationCenter
    private var dataSource: UICollectionViewDiffableDataSource<CVSection, Habit>!
    private var diagnosticsString = String()
    
    private var newButton: UIBarButtonItem!
    private var sortButton: UIBarButtonItem!
    private var sortAlertController: UIAlertController!
    private let sortKey = "homeSort"
    private var defaultSort: HomeSort = .dateCreated
    
    private let searchController = UISearchController()
    private var filteredHabits = [Habit]()
        
    // MARK: - Initializers
    init(collectionViewLayout layout: UICollectionViewLayout, persistenceManager: PersistenceService, defaults: UserDefaults, userNotifCenter: UNUserNotificationCenter, notifCenter: NotificationCenter) {
        self.persistenceManager = persistenceManager
        self.defaults = defaults
        self.notificationCenter = notifCenter
        self.userNotificationCenter = userNotifCenter
        
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - CollectionView Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.collectionViewLayout = UIHelper.createHabitsFlowLayout(in: collectionView)
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout { layout.sectionHeadersPinToVisibleBounds = true }
        
        self.collectionView.register(HomeHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        self.collectionView.register(HabitCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        self.notificationCenter.addObserver(self, selector: #selector(reloadHabits), name: NSNotification.Name(NotificationName.newDay.rawValue), object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(reloadHabits), name: NSNotification.Name(NotificationName.habits.rawValue), object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(finishFromNotes), name: NSNotification.Name(rawValue: NotificationName.finishHabitFromNotes.rawValue), object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(updateAppIconBadge), name: NSNotification.Name(rawValue: Setting.badgeAppIcon.rawValue), object: nil)
        
        configureNavigationBar()
        configureSearchController()
        configureDataSource()
        
        fetchHabits()
        
        if self.defaults.bool(forKey: DefaultsKeys.displayOnboarding.key) {
            presentOnboardingScreen(with: self.userNotificationCenter)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
    
    // MARK: - Configuration Functions
    private func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        self.newButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newTapped))
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Diagnostics", style: .plain, target: self, action: #selector(diagnostics))
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Notifications", style: .plain, target: self, action: #selector(printNofifications))
        
        if let sort = self.defaults.object(forKey: self.sortKey) {
            self.defaultSort = HomeSort(rawValue: sort as! String)!
        }
        
        if #available(iOS 14, *) {
            self.sortButton = UIBarButtonItem(image: UIImage(named: "arrow.up.arrow.down"), menu: createSortMenu())
        } else {
            self.sortAlertController = UIAlertController(title: "Sort by:", message: nil, preferredStyle: .actionSheet)
            configureSortAlertController()
            self.sortButton = UIBarButtonItem(image: UIImage(named: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(sortButtonTapped))
        }
        
        navigationItem.rightBarButtonItems = [self.newButton, self.sortButton]
    }
    
    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search habits"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
    }
    
    private func configureSortAlertController() {
        sortAlertController.message = "Current sort: \(self.defaultSort.rawValue)"
        sortAlertController.view.tintColor = .systemGreen
        HomeSort.allCases.forEach { (sort) in
            sortAlertController.addAction(UIAlertAction(title: sort.rawValue, style: .default, handler: { [weak self] (alert: UIAlertAction) in
                guard let self = self else { return }
                if let sortTitle = alert.title {
                    self.sortActionTriggered(sort: HomeSort(rawValue: sortTitle)!)
                    self.sortAlertController.message = "Current sort: \(sortTitle)"
                }
            }))
        }
        sortAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<CVSection, Habit>(collectionView: self.collectionView, cellProvider: { [weak self] (collectionView, indexPath, habit) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! HabitCell
            cell.set(delegate: self)
            cell.set(habit: habit)
            return cell
        })
                
        self.dataSource.supplementaryViewProvider = { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! HomeHeaderCell
            return header
        }
    }
    
    // MARK: - Functions
    private func updateDataSource(on habits: [Habit]) {
        var snapshot = NSDiffableDataSourceSnapshot<CVSection, Habit>()
        if !self.habits.isEmpty {
            snapshot.appendSections([.main])
            snapshot.appendItems(habits)
            DispatchQueue.main.async {
                self.dataSource.apply(snapshot, animatingDifferences: true)
                self.removeEmptyStateView()
            }
        } else {
            snapshot.deleteSections([.main])
            DispatchQueue.main.async {
                self.dataSource.apply(snapshot, animatingDifferences: false)
                self.showEmptyStateView()
            }
        }
    }
    
    private func fetchHabits() {
        self.habits = persistenceManager.fetch(Habit.self)
        if !self.habits.isEmpty {
            sortHabits()
        } else {
            updateDataSource(on: self.habits)
        }
    }
    
    @available(iOS 14, *)
    private func createSortMenu() -> UIMenu {
        var children = [UIAction]()
        HomeSort.allCases.forEach { (sort) in
            children.append(UIAction(title: sort.rawValue, state: sort.rawValue == self.defaultSort.rawValue ? .on : .off, handler: { [weak self] (action) in
                guard let self = self else { return }
                self.sortActionTriggered(sort: sort)
                self.sortButton.menu = self.createSortMenu()
            }))
        }
        return UIMenu(title: "Sort by:", children: children)
    }
    
    private func sortActionTriggered(sort: HomeSort) {
        self.defaultSort = sort
        self.defaults.set(sort.rawValue, forKey: self.sortKey)
        guard !self.habits.isEmpty else { return }
        sortHabits()
    }
    
    private func sortHabits() {
        switch self.defaultSort {
        case .alphabetical: self.habits.sort { (hab1, hab2) -> Bool in hab1.title! < hab2.title! }
        case .color: self.habits.sort { (hab1, hab2) -> Bool in hab1.color < hab2.color }
        case .dateCreated: self.habits.sort { (hab1, hab2) -> Bool in return hab1.dateCreated.compare(hab2.dateCreated) == .orderedAscending }
        case .dueToday: self.habits.sort { (hab1, hab2) -> Bool in hab1.statuses[CalUtility.getCurrentDay()] < hab2.statuses[CalUtility.getCurrentDay()] }
        case .flag: self.habits.sort { (hab1, hab2) -> Bool in hab1.flag && !hab2.flag }
        case .priority: self.habits.sort { (hab1, hab2) -> Bool in hab1.priority > hab2.priority }
        case .reminderTime: self.habits.sort { (hab1, hab2) -> Bool in
            let reminder1 = hab1.reminder ?? CalUtility.getFutureDate()
            let reminder2 = hab2.reminder ?? CalUtility.getFutureDate()
            return reminder1.compare(reminder2) == .orderedAscending
            }
        }
        updateDataSource(on: self.habits)
    }
    
    // MARK: - Selectors
    @objc func newTapped() {
        let newHabitVC = HabitDetailVC(persistenceManager: self.persistenceManager, defaults: self.defaults, delegate: self)
        let navController = UINavigationController(rootViewController: newHabitVC)
        navController.navigationBar.tintColor = .systemGreen
        DispatchQueue.main.async {
            self.present(navController, animated: true)
        }
    }
    
    @objc func sortButtonTapped() {
        DispatchQueue.main.async {
            self.present(self.sortAlertController, animated: true)
        }
    }
    
    @objc func reloadHabits() {
        DispatchQueue.main.async {
            self.configureDataSource()
            self.fetchHabits()
            self.updateAppIconBadge()
        }
    }
    
    @objc func finishFromNotes(_ notification: NSNotification) {
        if let habit = notification.userInfo?[NotificationName.finishHabitFromNotes.rawValue] as? Habit {
            finish(habit: habit, confetti: false)
        }
    }
    
    @objc func updateAppIconBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = self.defaults.bool(forKey: Setting.badgeAppIcon.rawValue) ? self.habits.filter({ $0.statuses[CalUtility.getCurrentDay()] == .incomplete }).count : 0
        }
    }
}

// MARK: - Delegates
extension HomeVC: HabitDetailDelegate {
    func add(habit: Habit) {
        self.userNotificationCenter.createNotificationRequest(forHabit: habit)
        self.persistenceManager.save()
        self.notificationCenter.reload(history: true)
        self.habits.append(habit)
        sortHabits()
        updateAppIconBadge()
    }
    
    func update(habit: Habit, deleteNotifications: (Bool, [Bool]), updateNotifications: Bool) {
        if deleteNotifications.0 { self.userNotificationCenter.deleteNotificationRequests(forDays: deleteNotifications.1, andUniqueID: habit.uniqueID) }
        if updateNotifications { self.userNotificationCenter.createNotificationRequest(forHabit: habit) }
        self.persistenceManager.save()
        self.notificationCenter.reload(history: true, archiveDetail: true, archivedHabitDetail: true)
        var snapshot = self.dataSource.snapshot()
        DispatchQueue.main.async {
            snapshot.reloadItems([habit])
            self.dataSource.apply(snapshot, animatingDifferences: true)
            self.sortHabits()
        }
        updateAppIconBadge()
    }
    
    func finish(habit: Habit, confetti: Bool) {
        self.userNotificationCenter.deleteNotificationRequests(forDays: habit.days, andUniqueID: habit.uniqueID)
        habit.archive.updateActive(toState: false)
        self.persistenceManager.delete(habit)
        self.notificationCenter.reload(history: true)
        if let index = self.habits.firstIndex(of: habit) {
            self.habits.remove(at: index)
            updateDataSource(on: self.habits)
        }
        
        if confetti {
            createAndStartParticles()
        }
        
        updateAppIconBadge()
    }
}

extension HomeVC: HabitCellDelegate {
    func presentNewHabitViewController(with habit: Habit) {
        let editHabitVC = HabitDetailVC(persistenceManager: self.persistenceManager, defaults: self.defaults, delegate: self, habitToEdit: habit)
        let navController = UINavigationController(rootViewController: editHabitVC)
        navController.navigationBar.tintColor = .systemGreen
        DispatchQueue.main.async {
            self.present(navController, animated: true)
        }
    }
    
    func checkboxSelectionChanged(atIndex index: Int, forHabit habit: Habit, fromStatus oldStatus: Status, toStatus newStatus: Status, forState state: Bool?) {
        habit.checkBoxPressed(fromStatus: oldStatus, toStatus: newStatus, atIndex: index, withState: state)
        self.persistenceManager.save()
        self.notificationCenter.reload(history: true, archiveDetail: true, archivedHabitDetail: true)
        
        if habit.archive.completedTotal == habit.goal {
            presentGoalReachedViewController(withHabit: habit, andDelegate: self)
        }
        
        if index == CalUtility.getCurrentDay() && self.defaultSort == .dueToday {
            sortHabits()
        }
        
        if index == CalUtility.getCurrentDay() {
            updateAppIconBadge()
        }
    }
    
    func presentAlertController(with alert: UIAlertController) {
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    func pushViewController(archivedHabit: ArchivedHabit) { }
    func checkboxSelectionChangedForArchivedHabit(atIndex index: Int, fromStatus oldStatus: Status, toStatus newStatus: Status, forState state: Bool?) { }
}

extension HomeVC: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let filter = searchController.searchBar.text else { return }
        if filter.isEmpty { updateDataSource(on: self.habits); return }
        
        filteredHabits = self.habits.filter { ($0.title?.lowercased().contains(filter.lowercased()))! }
        updateDataSource(on: filteredHabits)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        updateDataSource(on: self.habits)
    }
}

extension HomeVC: GoalReachedDelegate {
    func finishButtonTapped(forHabit habit: Habit) {
        finish(habit: habit, confetti: false)
    }
    
    func adjustButtonTapped(forHabit habit: Habit) {
        let goalViewController = GoalsVC(habit: habit, persistenceManager: self.persistenceManager)
        let navController = UINavigationController(rootViewController: goalViewController)
        DispatchQueue.main.async {
            self.present(navController, animated: true)
        }
    }
}

extension HomeVC {
    @objc func printNofifications() {
        self.userNotificationCenter.getPendingNotificationRequests { (requests) in
            requests.forEach { (request) in
                print(request)
            }
        }
    }
    
    @objc func diagnostics() {
        for habit in self.persistenceManager.fetch(Archive.self) {
            self.diagnosticsString.append(habit.stringRepresentation())
        }
        print(self.diagnosticsString)
//        self.userNotificationCenter.getPendingNotificationRequests { [weak self] (requests) in
//            guard let self = self else { return }
//            requests.forEach { (request) in
//                self.diagnosticsString.append(request.description)
//            }
//            DispatchQueue.main.async {
//                let diagnosticsFile = self.getDocumentsDirectory().appendingPathComponent("diagnostics.txt")
//                do {
//                    try self.diagnosticsString.write(to: diagnosticsFile, atomically: true, encoding: String.Encoding.utf8)
//                } catch {
//                    return
//                }
//                let activityController = UIActivityViewController(activityItems: [diagnosticsFile], applicationActivities: nil)
//                self.present(activityController, animated: true)
//                self.diagnosticsString = String()
//            }
//        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
