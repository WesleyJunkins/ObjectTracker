//
//  ReferenceObjectLoader.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  The class that loads all available reference objects.
//

import ARKit
import RealityKit

/// A class responsible for loading and managing AR reference objects.
@MainActor
@Observable
final class ReferenceObjectLoader {
    
    // MARK: - Properties

    /// The list of all loaded reference objects.
    private(set) var referenceObjects = [ReferenceObject]()

    /// The list of reference objects currently enabled for tracking.
    var enabledReferenceObjects = [ReferenceObject]()

    /// The count of enabled reference objects.
    var enabledReferenceObjectsCount: Int { enabledReferenceObjects.count }

    /// A dictionary mapping reference object IDs to their corresponding USDZ models as entities.
    private(set) var usdzsPerReferenceObjectID = [UUID: Entity]()

    /// Tracks whether loading has already started to prevent multiple operations.
    private var didStartLoading = false

    /// Total number of files to load.
    private var fileCount: Int = 0

    /// Number of files successfully loaded.
    private var filesLoaded: Int = 0

    /// Loading progress represented as a fraction (0.0 to 1.0).
    private(set) var progress: Float = 1.0

    /// Indicates whether all reference objects have finished loading.
    var didFinishLoading: Bool { progress >= 1.0 }

    // MARK: - Private Methods

    /// Marks one file as loaded and updates the progress.
    private func finishedOneFile() {
        filesLoaded += 1
        updateProgress()
    }

    /// Updates the loading progress based on the number of files loaded.
    private func updateProgress() {
        if fileCount == 0 {
            progress = 1.0
        } else if filesLoaded == fileCount {
            progress = 1.0
        } else {
            progress = Float(filesLoaded) / Float(fileCount)
        }
    }

    // MARK: - Public Methods

    /// Loads built-in reference objects from the app's main bundle.
    func loadBuiltInReferenceObjects() async {
        // Ensure the loading process runs only once.
        guard !didStartLoading else { return }
        didStartLoading.toggle()

        print("Looking for reference objects in the main bundle ...")

        // Locate reference object files in the main bundle.
        var referenceObjectFiles: [String] = []
        if let resourcesPath = Bundle.main.resourcePath {
            try? referenceObjectFiles = FileManager.default.contentsOfDirectory(atPath: resourcesPath).filter { $0.hasSuffix(".referenceobject") }
        }

        fileCount = referenceObjectFiles.count
        updateProgress()

        // Load each reference object asynchronously.
        await withTaskGroup(of: Void.self) { group in
            for file in referenceObjectFiles {
                let objectURL = Bundle.main.bundleURL.appending(path: file)
                group.addTask {
                    await self.loadReferenceObject(objectURL)
                    await self.finishedOneFile()
                }
            }
        }
    }

    /// Loads a single reference object from a file URL.
    /// - Parameter url: The URL of the reference object file.
    private func loadReferenceObject(_ url: URL) async {
        var referenceObject: ReferenceObject
        do {
            print("Loading reference object from \(url)")
            // Load the reference object file.
            try await referenceObject = ReferenceObject(from: url)
        } catch {
            fatalError("Failed to load reference object with error \(error)")
        }

        // Add the reference object to the list and sort alphabetically by name.
        referenceObjects.append(referenceObject)
        referenceObjects = referenceObjects.sorted { $0.name < $1.name }

        // Enable the reference object for tracking.
        enabledReferenceObjects.append(referenceObject)

        // Load the associated USDZ model if available.
        if let usdzPath = referenceObject.usdzFile {
            var entity: Entity? = nil

            do {
                // Load the USDZ file as an entity.
                try await entity = Entity(contentsOf: usdzPath)
            } catch {
                print("Failed to load model \(usdzPath.absoluteString)")
            }

            usdzsPerReferenceObjectID[referenceObject.id] = entity
        }
    }

    /// Adds a new reference object from a specified URL.
    /// - Parameter url: The URL of the reference object file.
    func addReferenceObject(_ url: URL) async {
        fileCount += 1
        await self.loadReferenceObject(url)
        self.finishedOneFile()
    }

    /// Removes a specific reference object.
    /// - Parameter referenceObject: The reference object to remove.
    func removeObject(_ referenceObject: ReferenceObject) {
        referenceObjects.removeAll { $0.id == referenceObject.id }
        enabledReferenceObjects.removeAll { $0.id == referenceObject.id }
        fileCount = referenceObjects.count
    }

    /// Removes multiple reference objects at the specified offsets.
    /// - Parameter offsets: The offsets of the reference objects to remove.
    func removeObjects(atOffsets offsets: IndexSet) {
        referenceObjects.remove(atOffsets: offsets)
        // Remove corresponding enabled objects as well.
        enabledReferenceObjects.removeAll(where: { object in
            !referenceObjects.contains(where: { $0.id == object.id })
        })
        fileCount = referenceObjects.count
    }
}
