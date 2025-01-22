//
//  ListEntryView.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  An entry in a list of reference objects.
//

import SwiftUI
import ARKit

/// A view representing an entry in the list of reference objects.
struct ListEntryView: View {
    /// The reference object being represented by this entry.
    var referenceObject: ReferenceObject

    /// The loader managing the reference objects.
    var referenceObjectLoader: ReferenceObjectLoader

    /// The body of the view, containing a toggle to enable or disable the reference object.
    var body: some View {
        // Create a binding to control whether the reference object is enabled or not.
        let binding = Binding(
            // Get the current enabled state of the reference object.
            get: { referenceObjectLoader.enabledReferenceObjects.contains(referenceObject) },
            
            // Update the enabled state when the toggle changes.
            set: { enabled in
                if enabled {
                    // Add the reference object to the enabled list.
                    referenceObjectLoader.enabledReferenceObjects.append(referenceObject)
                } else {
                    // Remove the reference object from the enabled list.
                    referenceObjectLoader.enabledReferenceObjects.removeAll(where: { $0.id == referenceObject.id })
                }
            }
        )

        // A toggle control with the reference object's name as the label.
        Toggle(isOn: binding, label: {
            Text("\(referenceObject.name)") // Display the name of the reference object.
        })
    }
}
