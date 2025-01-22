//
//  InfoLabel.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  A text view describing the current app state.
//

import SwiftUI

/// A view that displays an informational message based on the app's state.
struct InfoLabel: View {
    /// The application state object, used to determine the current message to display.
    let appState: AppState
    
    /// The body of the view, conditionally showing a message if available.
    var body: some View {
        // Check if there is an informational message to display.
        if let infoMessage {
            Text(infoMessage) // Display the message as a text view.
                .font(.subheadline) // Use a smaller, secondary font style.
                .multilineTextAlignment(.center) // Center-align the text for better readability.
        }
    }

    /// A computed property that determines the informational message to display.
    @MainActor
    var infoMessage: String? {
        // Check if the app lacks required platform support.
        if !appState.allRequiredProvidersAreSupported {
            return "Sorry, this app requires functionality that isn't supported on this platform."
        // Check if the app lacks necessary authorizations.
        } else if !appState.allRequiredAuthorizationsAreGranted {
            return "Sorry, this app is missing necessary authorizations. You can change this in the Privacy & Security settings."
        }
        // Return nil if there is no message to display.
        return nil
    }
}
