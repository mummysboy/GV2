//
//  GV2App.swift
//  GV2
//
//  Created by Isaac Hirsch on 7/9/25.
//

import SwiftUI

@main
struct GV2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
