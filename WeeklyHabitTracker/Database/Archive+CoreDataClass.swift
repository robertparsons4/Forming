//
//  Archive+CoreDataClass.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 6/12/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Archive)
public class Archive: NSManagedObject {
    func updateCurrentArchivedHabit(toStatus status: Status, atIndex index: Int) {
        if let archivedHabit = self.archivedHabits?.lastObject as? ArchivedHabit {
            archivedHabit.updateStatus(toStatus: status, atIndex: index)
        }
    }
    
    func updateCurrentArchivedHabit(withStatuses statuses: [Status]) {
        if let archivedHabit = self.archivedHabits?.lastObject as? ArchivedHabit {
            archivedHabit.updateStatuses(toStatuses: statuses)
        }
    }
    
    private func getStatuses(from days: [Bool]) -> [Status] {
        var statuses = [Status]()
        for day in days {
            if day { statuses.append(.incomplete) }
            else { statuses.append(.empty) }
        }
        return statuses
    }
    
    private func getDays() -> [Bool] {
        if let archivedHabit = self.archivedHabits?.lastObject as? ArchivedHabit {
            var days = [Bool]()
            for status in archivedHabit.statuses {
                if status != .empty { days.append(true) }
                else { days.append(false) }
            }
            return days
        }
        return [false, false, false, false, false, false, false]
    }
    
    func updateActive(toState state: Bool) {
        self.active = state
    }
    
    func updateStats(fromStatus oldStatus: Status, toStatus newStatus: Status) {
        switch oldStatus {
        case .completed:
            switch newStatus {
            case .completed: ()
            case .failed: self.completedTotal -= 1; self.failedTotal += 1
            case .incomplete: self.completedTotal -= 1; self.incompleteTotal += 1
            case .empty: self.completedTotal -= 1
            }
        case .failed:
            switch newStatus {
            case .completed: self.failedTotal -= 1; self.completedTotal += 1
            case .failed: ()
            case .incomplete: self.failedTotal -= 1; self.incompleteTotal += 1
            case .empty: self.failedTotal -= 1
            }
        case .incomplete:
            switch newStatus {
            case .completed: self.incompleteTotal -= 1; self.completedTotal += 1
            case .failed: self.incompleteTotal -= 1; self.failedTotal += 1
            case .incomplete: ()
            case .empty: self.incompleteTotal -= 1
            }
        case .empty:
            switch newStatus {
            case .completed: self.completedTotal += 1
            case .failed: self.failedTotal += 1
            case .incomplete: self.incompleteTotal += 1
            case .empty: ()
            }
        }
        
        let total = Double(self.completedTotal + self.failedTotal)
        if total != 0 { self.successRate = Double(self.completedTotal) / total * 100 }
        else { self.successRate = 100.0 }
    }
    
    func createNewArchivedHabit(fromArchivedHabit archivedHabit: ArchivedHabit, withStatuses statuses: [Status]) {
        archivedHabit.archive = self
        archivedHabit.statuses = statuses
        archivedHabit.startDate = CalUtility.getFirstDateOfWeek()
        archivedHabit.endDate = CalUtility.getLastDateOfWeek()
        insertIntoArchivedHabits(archivedHabit, at: 0)
    }
    
    func createNewHabit() -> Habit {
        let newHabit = Habit(context: PersistenceService.shared.context)
        newHabit.title = self.title
        newHabit.days = getDays()
        newHabit.statuses = getStatuses(from: newHabit.days)
        newHabit.color = self.color
        newHabit.priority = self.priority
        newHabit.reminder = self.reminder
        newHabit.flag = self.flag
        newHabit.dateCreated = CalUtility.getCurrentDate()
        newHabit.buttonState = false
        newHabit.uniqueID = UUID().uuidString
        newHabit.archive = self
        return newHabit
    }
    
    func reset() {
        self.completedTotal = 0
        self.failedTotal = 0
        self.incompleteTotal = 0
        
        self.habit.resetStatuses()
        self.habit.updateButtonState(toState: false)
        
        if let array = self.archivedHabits?.array as? [ArchivedHabit] {
            for archivedHabit in array {
                PersistenceService.shared.delete(archivedHabit)
            }
        }
        createNewArchivedHabit(fromArchivedHabit: ArchivedHabit(context: PersistenceService.shared.context), withStatuses: self.habit.statuses)
    }
    
    func restore() {
        updateActive(toState: true)
        self.habit = createNewHabit()
        // if restored in same week as being deleted, update stats and latest archived habit's statuses
        // else also update stats
    }
}
