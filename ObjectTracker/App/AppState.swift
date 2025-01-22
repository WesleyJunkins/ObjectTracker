//
//  AppState.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  The app's overall state
//

import ARKit

/// The main class managing the app's state, including ARKit sessions and object tracking.
@MainActor
@Observable
class AppState {
    // Indicates whether the immersive space is currently open.
    var isImmersiveSpaceOpened = false
    
    // Handles the loading of reference objects used for AR object tracking.
    let referenceObjectLoader = ReferenceObjectLoader()

    /// Called when the immersive space is exited.
    func didLeaveImmersiveSpace() {
        // Stops the current ARKit session as it is no longer needed.
        arkitSession.stop()
        isImmersiveSpaceOpened = false
    }

    // MARK: - ARKit state

    // The ARKit session used for running AR functionality.
    private let arkitSession = ARKitSession()
    
    // The provider responsible for managing object tracking in AR.
    private var objectTracking: ObjectTrackingProvider? = nil
    
    // Indicates whether object tracking has started running.
    var objectTrackingStartedRunning = false
    
    // Indicates if any ARKit providers have stopped due to an error.
    var providersStoppedWithError = false
    
    // The current authorization status for world sensing.
    var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined

    /// Starts tracking objects in AR using the enabled reference objects.
    /// - Returns: The object tracking provider if successful.
    func startTracking() async -> ObjectTrackingProvider? {
        // Ensure there are reference objects to track.
        let referenceObjects = referenceObjectLoader.enabledReferenceObjects
        guard !referenceObjects.isEmpty else {
            fatalError("No reference objects to start tracking")
        }

        // Create a new object tracking provider for the reference objects.
        let objectTracking = ObjectTrackingProvider(referenceObjects: referenceObjects)
        do {
            // Attempt to run the ARKit session with the new provider.
            try await arkitSession.run([objectTracking])
        } catch {
            print("Error: \(error)" )
            return nil
        }
        self.objectTracking = objectTracking
        return objectTracking
    }

    // Determines if all required authorizations are granted for AR functionality.
    var allRequiredAuthorizationsAreGranted: Bool {
        worldSensingAuthorizationStatus == .allowed
    }

    // Determines if all required ARKit providers are supported on the device.
    var allRequiredProvidersAreSupported: Bool {
        ObjectTrackingProvider.isSupported
    }

    // Determines if the app can enter the immersive space.
    var canEnterImmersiveSpace: Bool {
        allRequiredAuthorizationsAreGranted && allRequiredProvidersAreSupported
    }

    /// Requests authorization for world sensing capabilities.
    func requestWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.requestAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }

    /// Queries the current authorization status for world sensing.
    func queryWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.queryAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }

    /// Monitors ARKit session events and updates the app state accordingly.
    func monitorSessionEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(let providers, let newState, let error):
                switch newState {
                case .initialized:
                    break
                case .running:
                    // Check if object tracking has started running.
                    guard objectTrackingStartedRunning == false, let objectTracking else { continue }
                    for provider in providers where provider === objectTracking {
                        objectTrackingStartedRunning = true
                        break
                    }
                case .paused:
                    break
                case .stopped:
                    // Handle stopping of the object tracking provider.
                    guard objectTrackingStartedRunning == true, let objectTracking else { continue }
                    for provider in providers where provider === objectTracking {
                        objectTrackingStartedRunning = false
                        break
                    }
                    if let error {
                        print("An error occurred: \(error)")
                        providersStoppedWithError = true
                    }
                @unknown default:
                    break
                }
            case .authorizationChanged(let type, let status):
                print("Authorization type \(type) changed to \(status)")
                if type == .worldSensing {
                    worldSensingAuthorizationStatus = status
                }
            default:
                print("An unknown event occurred \(event)")
            }
        }
    }
}
