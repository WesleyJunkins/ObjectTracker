//
//  ObjectTrackerApp.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  This is the app's main entry point.
//

import SwiftUI

private enum UIIdentifier {
    static let immersiveSpace = "Object tracking"
}

@main
@MainActor
struct ObjectTrackingApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            HomeView(
                appState: appState,
                immersiveSpaceIdentifier: UIIdentifier.immersiveSpace
            )
            .task {
                if appState.allRequiredProvidersAreSupported {
                    await appState.referenceObjectLoader.loadBuiltInReferenceObjects()
                }
            }
        }
        .windowStyle(.plain)

        ImmersiveSpace(id: UIIdentifier.immersiveSpace) {
            ObjectTrackingRealityView(appState: appState)
        }
    }
}
