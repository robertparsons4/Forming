//
//  AppDelegate.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/14/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import UIKit
import BackgroundTasks
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var currentDate: Date?
    private var key = "date"
    private let defaults = UserDefaults.standard
    private let persistenceService = PersistenceService.shared
    private let notificationCenter = NotificationCenter.default
    private let userNotificationCenter = UNUserNotificationCenter.current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted { print("granted") }
            else { print("not granted") }
        }
        
        if let date = defaults.object(forKey: self.key) as? Date { self.currentDate = date }
        else { self.currentDate = CalUtility.getCurrentDate(); self.defaults.set(self.currentDate, forKey: self.key) }
        if !Calendar.current.isDateInToday(self.currentDate!) { dayChanged() }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.forming.refresh", using: nil) { (task) in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        notificationCenter.addObserver(self, selector: #selector(dayChanged), name: .NSCalendarDayChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        return true
    }
    
    func getUserDefaults() -> UserDefaults { return self.defaults }
    func getPersistenceService() -> PersistenceService { return self.persistenceService }
    func getNotificationCenter() -> NotificationCenter { return self.notificationCenter }
    func getUserNotificationCenter() -> UNUserNotificationCenter { return self.userNotificationCenter }
    
    func scheduleLocalNotification(withTitle title: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Notification"
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        self.userNotificationCenter.add(request)
    }
    
    @objc func enteredBackground() {
        self.scheduleAppRefresh()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        self.scheduleAppRefresh()
        self.persistenceService.save()
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.forming.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Successfully scheduled app refresh.")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        if Calendar.current.isDateInToday(self.currentDate!) {
            queue.addOperation {
                print("do nothing")
                self.scheduleLocalNotification(withTitle: "Do Nothing Refresh")
            }
        } else {
            queue.addOperation {
                self.dayChanged()
                self.scheduleLocalNotification(withTitle: "Day Change Refresh")
            }
        }

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            queue.cancelAllOperations()
        }

        let lastOperation = queue.operations.last
        lastOperation?.completionBlock = {
            task.setTaskCompleted(success: !(lastOperation?.isCancelled ?? false))
        }
    }
    
    @objc func dayChanged() {
        self.currentDate = CalUtility.getCurrentDate()
        self.defaults.set(self.currentDate, forKey: self.key)
        let newDay = CalUtility.getCurrentDay()
        
        let habits = self.persistenceService.fetch(Habit.self)
        switch newDay {
        case 0:
            for habit in habits {
                let newArchivedHabit = ArchivedHabit(context: self.persistenceService.context)
                habit.weekChanged(withNewArchivedHabit: newArchivedHabit)
            }
        default:
            for habit in habits { habit.dayChanged(toDay: newDay) }
        }
        
        self.persistenceService.save()
        self.notificationCenter.post(name: NSNotification.Name("newDay"), object: nil)
    }
}
