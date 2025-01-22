//
//  ObjectTrackerApp.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  This is the app's main entry point.
//

import SwiftUI

/// A private enumeration for defining UI identifiers.
private enum UIIdentifier {
    /// Identifier for the immersive space.
    static let immersiveSpace = "Object tracking"
}

/// The main entry point for the ObjectTracker app.
@main
@MainActor
struct ObjectTrackingApp: App {
    /// The application state, managing AR sessions and tracking states.
    @State private var appState = AppState()

    /// The body of the app, defining its scenes and windows.
    var body: some Scene {
        // The main window group for the app's user interface.
        WindowGroup {
            // The home view is the primary UI displayed in this window group.
            HomeView(
                appState: appState,
                immersiveSpaceIdentifier: UIIdentifier.immersiveSpace
            )
            .task {
                // Load built-in reference objects if all required AR providers are supported.
                if appState.allRequiredProvidersAreSupported {
                    await appState.referenceObjectLoader.loadBuiltInReferenceObjects()
                }
            }
        }
        .windowStyle(.plain) // Use a plain window style for the app.

        // Define an immersive space for object tracking.
        ImmersiveSpace(id: UIIdentifier.immersiveSpace) {
            ObjectTrackingRealityView(appState: appState)
        }
    }
}
