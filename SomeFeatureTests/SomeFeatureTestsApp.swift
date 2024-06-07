//
//  SomeFeatureTestsApp.swift
//  SomeFeatureTests
//
//  Created by Arbab Nawaz on 6/5/24.
//

import SwiftUI
import SwiftData
import TipKit


private struct IsProKey: EnvironmentKey {
  static let defaultValue = false
}


extension EnvironmentValues {
    var isPro: Bool {
        get { self[IsProKey.self] }
        set { self[IsProKey.self] = newValue }
      }
}


@main
struct SomeFeatureTestsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.isPro, true)
                .task {
                    try? Tips.resetDatastore()
                    // Configure and load your tips at app launch.
                    try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
            }
        }
        .modelContainer(sharedModelContainer)
        
    }
}
