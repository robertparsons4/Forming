//
//  HistoryCollectionViewController.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/14/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import UIKit

private let reuseIdentifier = "History Title Cell"
private let sectionReuseIdentifier = "History Section Header"

class HistoryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    private var archives: [Archive] = []
    private var activeHabits: [Archive] = []
    private var deletedHabits: [Archive] = []
    private let persistenceManager: PersistenceService
    private let notificationCenter: NotificationCenter
    private var dataSource: UICollectionViewDiffableDataSource<HistorySection, Archive>!
    
    private let searchController = UISearchController()
    private var filteredArchives: [Archive] = []
    private var isSearching = false
    
    // MARK: - Initializers
    init(collectionViewLayout layout: UICollectionViewLayout, persistenceManager: PersistenceService, notifCenter: NotificationCenter) {
        self.persistenceManager = persistenceManager
        self.notificationCenter = notifCenter
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 30)
    }
    
    // MARK: - CollectionView Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        navigationController?.navigationBar.prefersLargeTitles = true
        collectionView.collectionViewLayout = UIHelper.createTwoColumnFlowLayout(in: collectionView)
        self.notificationCenter.addObserver(self, selector: #selector(reloadArchives), name: NSNotification.Name(rawValue: "reload"), object: nil)

        self.collectionView.register(HistoryTitleCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.register(HistorySectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: sectionReuseIdentifier)
        
        configureSearchController()
        configureDataSource()
        updateArchives()
    }
    
    // MARK: - Configuration Functions
    func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for Archived Habit"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
    }
    
    func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<HistorySection, Archive>(collectionView: self.collectionView, cellProvider: { (collectionView, indexPath, archive) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! HistoryTitleCell
            cell.setTitleLabelText(archive.title)
            cell.setBackgroundColor(FormingColors.getColor(fromValue: archive.color))
            return cell
        })
        
        self.dataSource.supplementaryViewProvider = { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: sectionReuseIdentifier, for: indexPath) as! HistorySectionHeader
            switch indexPath.section {
            case 0: header.set(title: "Active Habits")
            case 1: header.set(title: self.deletedHabits.count > 0 ? "Deleted Habits" : "")
            default: header.set(title: "Error")
            }
            
            return header
        }
    }

    // MARK: CollectionView Functions
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let activeArray = self.isSearching ? self.filteredArchives : self.archives
//        let archive = activeArray[indexPath.row]
        guard let archive = self.dataSource.itemIdentifier(for: indexPath) else { print("selection error"); return }
        let archiveDetailVC = ArchiveDetailCollectionViewController(archive: archive)
        navigationController?.pushViewController(archiveDetailVC, animated: true)
    }
    
    // MARK: - Functions
    func updateData(on activeHabits: [Archive], and deletedHabits: [Archive]) {
        var snapshot = NSDiffableDataSourceSnapshot<HistorySection, Archive>()
        snapshot.appendSections([.activeHabits, .deletedHabits])
        snapshot.appendItems(activeHabits, toSection: .activeHabits)
        snapshot.appendItems(deletedHabits, toSection: .deletedHabits)
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    func updateArchives() {
        self.archives = persistenceManager.fetch(Archive.self)
        guard !self.archives.isEmpty else {
            self.showEmptyStateView(withText: "To start recording habit history, create a new habit.")
            return
        }
        self.removeEmptyStateView()
        self.activeHabits = self.archives.filter( { $0.active == true } )
        self.deletedHabits = self.archives.filter( { $0.active == false } )

        self.activeHabits.sort { (archive1, archive2) -> Bool in archive1.title < archive2.title}
        self.deletedHabits.sort { (archive1, archive2) -> Bool in archive1.title < archive2.title}
        updateData(on: self.activeHabits, and: self.deletedHabits)
    }
    
    // MARK: - Selectors
    @objc func reloadArchives() {
        updateArchives()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}

// MARK: - Delegates
extension HistoryCollectionViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let filter = searchController.searchBar.text else { return }
        if filter.isEmpty { updateData(on: self.activeHabits, and: self.deletedHabits); isSearching = false; return }
        self.isSearching = true
        
        filteredArchives = self.activeHabits.filter { ($0.title.lowercased().contains(filter.lowercased())) }
        updateData(on: filteredArchives, and: self.deletedHabits)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.isSearching = false
        updateData(on: self.activeHabits, and: self.deletedHabits)
    }
}
