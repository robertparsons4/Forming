//
//  Sorting.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/28/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import Foundation

enum HomeSort: String, CaseIterable {
    case alphabetical = "Alphabetical"
    case color = "Color"
    case dateCreated = "Date Created"
    case dueToday = "Due Today"
    case flag = "Flag"
    case priority = "Priority"
    case reminderTime = "Reminder Time"
}

enum ArchiveDetailSort: String, CaseIterable {
    case dateAscending = "Date Ascending"
    case dateDescending = "Date Descending"
}
