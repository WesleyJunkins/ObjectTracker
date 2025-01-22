//
//  HomeView.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  The main user interface.
//

import SwiftUI
import ARKit
import RealityKit
import UniformTypeIdentifiers

/// The main user interface for the ObjectTracker app, responsible for managing and displaying
/// reference objects, immersive space controls, and application state.
struct HomeView: View {
    /// Binds to the overall application state.
    @Bindable var appState: AppState

    /// The identifier for the immersive space session.
    let immersiveSpaceIdentifier: String

    /// The file type for reference object files.
    let referenceObjectUTType = UTType("com.apple.arkit.referenceobject")!

    /// Access the immersive space opening environment.
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    /// Access the immersive space dismissal environment.
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    /// Tracks the current lifecycle phase of the scene (e.g., active or background).
    @Environment(\.scenePhase) private var scenePhase

    /// State to track whether the file importer is open.
    @State private var fileImporterIsOpen = false

    /// The currently selected reference object ID, if any.
    @State var selectedReferenceObjectID: ReferenceObject.ID?

    /// The body of the view, defining its layout and behavior.
    var body: some View {
        Group {
            // Show the reference object list if the app can enter immersive space.
            if appState.canEnterImmersiveSpace {
                referenceObjectList
                    .frame(minWidth: 400, minHeight: 300)
            } else {
                // Display an informational message if immersive space is unavailable.
                InfoLabel(appState: appState)
                    .padding(.horizontal, 30)
                    .frame(minWidth: 400, minHeight: 300)
                    .fixedSize()
            }
        }
        .glassBackgroundEffect()
        .toolbar {
            ToolbarItem(placement: .bottomOrnament) {
                // Add controls for immersive space management.
                if appState.canEnterImmersiveSpace {
                    VStack {
                        // Button to start or stop tracking based on the immersive space state.
                        if !appState.isImmersiveSpaceOpened {
                            Button("Start Tracking \(appState.referenceObjectLoader.enabledReferenceObjectsCount) Object(s)") {
                                Task {
                                    switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                                    case .opened:
                                        break
                                    case .error:
                                        print("An error occurred when trying to open the immersive space \(immersiveSpaceIdentifier)")
                                    case .userCancelled:
                                        print("The user declined opening immersive space \(immersiveSpaceIdentifier)")
                                    @unknown default:
                                        break
                                    }
                                }
                            }
                            .disabled(!appState.canEnterImmersiveSpace || appState.referenceObjectLoader.enabledReferenceObjectsCount == 0)
                        } else {
                            Button("Stop Tracking") {
                                Task {
                                    await dismissImmersiveSpace()
                                    appState.didLeaveImmersiveSpace()
                                }
                            }

                            // Show a progress indicator if object tracking has not yet started.
                            if !appState.objectTrackingStartedRunning {
                                HStack {
                                    ProgressView()
                                    Text("Please wait until all reference objects have been loaded")
                                }
                            }
                        }

                        // Provide feedback about entering or leaving immersive space.
                        Text(appState.isImmersiveSpaceOpened ?
                             "This leaves the immersive space." :
                             "This enters an immersive space, hiding all other apps."
                        )
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .fileImporter(isPresented: $fileImporterIsOpen, allowedContentTypes: [referenceObjectUTType], allowsMultipleSelection: true) { results in
            // Handle file import results.
            switch results {
            case .success(let fileURLs):
                Task {
                    // Try to load each selected file as a reference object.
                    for fileURL in fileURLs {
                        guard fileURL.startAccessingSecurityScopedResource() else {
                            print("Failed to get sandboxed access to the file \(fileURL)")
                            return
                        }
                        await appState.referenceObjectLoader.addReferenceObject(fileURL)
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
            case .failure(let error):
                print("Failed to open file with error: \(error)")
            }
        }
        .onChange(of: scenePhase, initial: true) {
            // Handle changes in the app's scene phase.
            print("HomeView scene phase: \(scenePhase)")
            if scenePhase == .active {
                Task {
                    // Recheck authorization status when returning to the foreground.
                    await appState.queryWorldSensingAuthorization()
                }
            } else {
                // Ensure the immersive space is closed if the view is no longer active.
                if appState.isImmersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appState.didLeaveImmersiveSpace()
                    }
                }
            }
        }
        .onChange(of: appState.providersStoppedWithError, { _, providersStoppedWithError in
            // Close the immersive space immediately if an error occurs.
            if providersStoppedWithError {
                if appState.isImmersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appState.didLeaveImmersiveSpace()
                    }
                }
                appState.providersStoppedWithError = false
            }
        })
        .task {
            // Request authorization for world sensing if needed.
            if appState.allRequiredProvidersAreSupported {
                await appState.requestWorldSensingAuthorization()
            }
        }
        .task {
            // Monitor changes in session events (e.g., authorization updates).
            await appState.monitorSessionEvents()
        }
    }

    /// A view displaying the list of reference objects.
    @MainActor
    var referenceObjectList: some View {
        NavigationSplitView {
            VStack(alignment: .leading) {
                // List of reference objects with delete functionality.
                List(selection: $selectedReferenceObjectID) {
                    ForEach(appState.referenceObjectLoader.referenceObjects, id: \.id) { referenceObject in
                        ListEntryView(referenceObject: referenceObject, referenceObjectLoader: appState.referenceObjectLoader)
                    }
                    .onDelete { indexSet in
                        appState.referenceObjectLoader.removeObjects(atOffsets: indexSet)
                    }
                }
                .navigationTitle("Reference objects")

                // Button to open the file importer for adding new reference objects.
                Button {
                    fileImporterIsOpen = true
                } label: {
                    Image(systemName: "plus")
                }
                .padding(.leading)
                .help("Add reference objects")
            }
            .padding(.vertical)
            .disabled(appState.isImmersiveSpaceOpened)

        } detail: {
            // Detail view for the selected reference object.
            if !appState.referenceObjectLoader.didFinishLoading {
                VStack {
                    Text("Loading reference objects…")
                    ProgressView(value: appState.referenceObjectLoader.progress)
                        .frame(maxWidth: 200)
                }
            } else if appState.referenceObjectLoader.referenceObjects.isEmpty {
                Text("Tap the + button to add reference objects, or include some in the 'Reference Objects' group of the app's Xcode project.")
            } else {
                if let selectedObject = appState.referenceObjectLoader.referenceObjects.first(where: { $0.id == selectedReferenceObjectID }) {
                    // Display the associated USDZ file if available.
                    if let path = selectedObject.usdzFile, !fileImporterIsOpen {
                        Model3D(url: path) { model in
                            model
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(0.5)
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Text("No preview available")
                    }
                } else {
                    Text("No object selected")
                }
            }
        }
    }
}
