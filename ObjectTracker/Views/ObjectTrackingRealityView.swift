//
//  ObjectTrackingRealityView.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  The view shown inside the immersive space.
//

import RealityKit
import ARKit
import SwiftUI

/// A SwiftUI view that displays AR object tracking content in the immersive space.
@MainActor
struct ObjectTrackingRealityView: View {
    /// The shared application state.
    var appState: AppState

    /// The root entity to which all AR objects are added.
    var root = Entity()

    /// A dictionary mapping anchor IDs to their visualizations.
    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]

    /// The body of the view, embedding a RealityKit view with AR content.
    var body: some View {
        RealityView { content in
            // Add the root entity to the AR content.
            content.add(root)

            Task {
                // Start object tracking using the app state.
                let objectTracking = await appState.startTracking()
                guard let objectTracking else {
                    return
                }

                // Process updates to object anchors in the AR session.
                for await anchorUpdate in objectTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    let id = anchor.id

                    switch anchorUpdate.event {
                    case .added:
                        // Create a visualization for the newly detected anchor.
                        let model = appState.referenceObjectLoader.usdzsPerReferenceObjectID[anchor.referenceObject.id]
                        let visualization = ObjectAnchorVisualization(for: anchor, withModel: model)
                        self.objectVisualizations[id] = visualization
                        root.addChild(visualization.entity)
                    case .updated:
                        // Update the visualization for the anchor if it exists.
                        objectVisualizations[id]?.update(with: anchor)
                    case .removed:
                        // Remove the visualization and its entity when the anchor is removed.
                        objectVisualizations[id]?.entity.removeFromParent()
                        objectVisualizations.removeValue(forKey: id)
                    }
                }
            }
        }
        .onAppear() {
            // Handle entering the immersive space.
            print("Entering immersive space.")
            appState.isImmersiveSpaceOpened = true
        }
        .onDisappear() {
            // Handle leaving the immersive space.
            print("Leaving immersive space.")

            // Remove all visualizations from the root entity.
            for (_, visualization) in objectVisualizations {
                root.removeChild(visualization.entity)
            }
            objectVisualizations.removeAll()

            // Update the app state to reflect the immersive space closure.
            appState.didLeaveImmersiveSpace()
        }
    }
}
