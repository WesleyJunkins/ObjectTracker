//
//  InfoLabel.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  A text view describing the current app state.
//

import SwiftUI

struct InfoLabel: View {
    let appState: AppState
    
    var body: some View {
        if let infoMessage {
            Text(infoMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
    }

    @MainActor
    var infoMessage: String? {
        if !appState.allRequiredProvidersAreSupported {
            return "Sorry, this app requires functionality that isn't supported on this platform."
        } else if !appState.allRequiredAuthorizationsAreGranted {
            return "Sorry, this app is missing necessary authorizations. You can change this in the Privacy & Security settings."
        }
        return nil
    }
}
