//
//  SettingsViewController.swift
//  WeeklyHabitTracker
//
//  Created by Robert Parsons on 4/20/20.
//  Copyright © 2020 Robert Parsons. All rights reserved.
//

import UIKit
import SwiftUI

class SettingsViewController: UIHostingController<SettingsSwiftUI> {
    
}

struct SettingsSwiftUI: View {
    var body: some View {
        NavigationView {
            List {
                Section(header:
                    VStack(spacing: 15) {
                        TipButton(title: "$0.99 Tip",
                                  message: "Thank you so much for your support!",
                                  leftMemoji: Memoji(imageName: "thumbsup-left"),
                                  rightMemoji: Memoji(imageName: "thumbsup-right"),
                                  backgroundColor: .systemGreen)
                        TipButton(title: "$4.99 Tip",
                                  message: "You're awesome! Thank you so much!",
                                  leftMemoji: Memoji(imageName: "celebration-left"),
                                  rightMemoji: Memoji(imageName: "celebration-right"),
                                  backgroundColor: .systemTeal)
                        TipButton(title: "$9.99 Tip",
                                  message: "Wow! I really appreciate it! Thank you!",
                                  leftMemoji: Memoji(imageName: "explosion-left"),
                                  rightMemoji: Memoji(imageName: "explosion-right"),
                                  backgroundColor: .systemOrange)
                    }.frame(width: UIScreen.main.bounds.width, height: (3 * 90) + (3 * 15), alignment: .top)) {
                        ListCell(image: Image("clock"), title: Text("Default Reminder Time"))
                        ListCell(image: Image("app.badge"), title: Text("Due Today Icon Badge"))
                        ListCell(image: Image(systemName: "faceid"), title: Text("Authentication"))
                }
            }.listStyle(GroupedListStyle())
                .environment(\.horizontalSizeClass, .regular)
                .navigationBarTitle(Text("Settings"))
        }
    }
}

struct TipButton: View {
    let title: String
    let message: String
    let leftMemoji: Memoji
    let rightMemoji: Memoji
    let backgroundColor: UIColor
    
    var body: some View {
        Button(action: {
            print(self.title)
        }) {
            HStack(spacing: 10) {
                leftMemoji
                VStack {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    Text(message)
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(width: 175, height: 50, alignment: .center)
                }
                rightMemoji
            }
        }.frame(width: UIScreen.main.bounds.width - 40, height: 90, alignment: .center)
            .background(Color(backgroundColor))
            .foregroundColor(Color(.label))
            .cornerRadius(14)
    }
}

struct Memoji: View {
    let imageName: String
    var body: some View {
        Image(imageName)
            .renderingMode(.original)
            .resizable()
            .frame(width: 65, height: 65, alignment: .center)
    }
}

struct ListCell: View {
    let image: Image
    let title: Text
    @State private var isOn = false
    
    var body: some View {
        HStack {
            image
            title
        }
    }
}

struct SettingsSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        Group {
           SettingsSwiftUI()
              .environment(\.colorScheme, .dark)

           SettingsSwiftUI()
              .environment(\.colorScheme, .light)
        }
    }
}
