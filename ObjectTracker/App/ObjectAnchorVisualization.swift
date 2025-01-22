//
//  ObjectAnchorVisualization.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  The visualization of an object anchor.
//

import ARKit
import RealityKit
import SwiftUI

/// Manages the visualization of an AR object anchor, including bounding boxes and model overlays.
@MainActor
class ObjectAnchorVisualization {
    
    // MARK: - Constants

    /// Base height for text descriptions.
    private let textBaseHeight: Float = 0.08

    /// Transparency level for visual elements.
    private let alpha: CGFloat = 0.7

    /// Scale factor for visualizing axes.
    private let axisScale: Float = 0.05

    // MARK: - Properties

    /// Visualization of the anchor's bounding box.
    var boundingBoxOutline: BoundingBoxOutline

    /// The root entity for this visualization.
    var entity: Entity

    // MARK: - Initialization

    /// Creates a visualization for a given object anchor.
    /// - Parameters:
    ///   - anchor: The object anchor to visualize.
    ///   - model: An optional 3D model to overlay on the anchor.
    init(for anchor: ObjectAnchor, withModel model: Entity? = nil) {
        // Initialize the bounding box outline.
        boundingBoxOutline = BoundingBoxOutline(anchor: anchor, alpha: alpha)
        
        // Create a root entity for all visualization elements.
        let entity = Entity()

        // Add axes to represent the anchor's origin.
        let originVisualization = Entity.createAxes(axisScale: axisScale, alpha: alpha)

        // If a model is provided, apply a yellow wireframe material to it.
        if let model {
            var wireframeMaterial = PhysicallyBasedMaterial()
            wireframeMaterial.triangleFillMode = .lines
            wireframeMaterial.faceCulling = .back
            wireframeMaterial.baseColor = .init(tint: .yellow)
            wireframeMaterial.blending = .transparent(opacity: 0.5)

            model.applyMaterialRecursively(wireframeMaterial)
            entity.addChild(model)
        }

        // Enable the bounding box visualization only if no model is provided.
        boundingBoxOutline.entity.isEnabled = model == nil

        // Add origin visualization and bounding box outline to the root entity.
        entity.addChild(originVisualization)
        entity.addChild(boundingBoxOutline.entity)

        // Position the root entity at the anchor's transform.
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.isEnabled = anchor.isTracked

        // Add a description label to the anchor visualization.
        let descriptionEntity = Entity.createText(anchor.referenceObject.name, height: textBaseHeight * axisScale)
        descriptionEntity.transform.translation.x = textBaseHeight * axisScale
        descriptionEntity.transform.translation.y = anchor.boundingBox.extent.y * 0.5
        entity.addChild(descriptionEntity)

        self.entity = entity
    }

    /// Updates the visualization to reflect changes in the anchor.
    /// - Parameter anchor: The updated object anchor.
    func update(with anchor: ObjectAnchor) {
        // Enable or disable the visualization based on the anchor's tracking state.
        entity.isEnabled = anchor.isTracked
        guard anchor.isTracked else { return }

        // Update the root entity's transform and bounding box outline.
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        boundingBoxOutline.update(with: anchor)
    }

    // MARK: - BoundingBoxOutline

    /// Represents the outline of a bounding box for an object anchor.
    @MainActor
    class BoundingBoxOutline {
        // Thickness of the bounding box wires.
        private let thickness: Float = 0.0025

        /// Current extent of the bounding box.
        private var extent: SIMD3<Float> = [0, 0, 0]

        /// Entities representing the bounding box wires.
        private var wires: [Entity] = []

        /// The root entity for the bounding box visualization.
        var entity: Entity

        /// Initializes the bounding box outline for a given anchor.
        /// - Parameters:
        ///   - anchor: The object anchor to visualize.
        ///   - color: The color of the bounding box wires.
        ///   - alpha: The transparency level of the wires.
        fileprivate init(anchor: ObjectAnchor, color: UIColor = .yellow, alpha: CGFloat = 1.0) {
            // Create a root entity for the bounding box.
            let entity = Entity()

            // Create a material for the wires.
            let materials = [UnlitMaterial(color: color.withAlphaComponent(alpha))]
            
            // Generate a basic box mesh for the wires.
            let mesh = MeshResource.generateBox(size: [1.0, 1.0, 1.0])

            // Create wire entities and add them to the root entity.
            for _ in 0...11 {
                let wire = ModelEntity(mesh: mesh, materials: materials)
                wires.append(wire)
                entity.addChild(wire)
            }

            self.entity = entity

            // Update the bounding box to match the anchor's properties.
            update(with: anchor)
        }

        /// Updates the bounding box outline to match the anchor.
        /// - Parameter anchor: The updated object anchor.
        fileprivate func update(with anchor: ObjectAnchor) {
            // Update the root entity's position to match the anchor's bounding box center.
            entity.transform.translation = anchor.boundingBox.center

            // If the extent hasn't changed, no update is needed.
            guard anchor.boundingBox.extent != extent else { return }
            extent = anchor.boundingBox.extent

            // Update the positions and scales of the wires based on the new extent.
            for index in 0...3 {
                wires[index].scale = SIMD3<Float>(extent.x, thickness, thickness)
                wires[index].position = [0, extent.y / 2 * (index % 2 == 0 ? -1 : 1), extent.z / 2 * (index < 2 ? -1 : 1)]
            }

            for index in 4...7 {
                wires[index].scale = SIMD3<Float>(thickness, extent.y, thickness)
                wires[index].position = [extent.x / 2 * (index % 2 == 0 ? -1 : 1), 0, extent.z / 2 * (index < 6 ? -1 : 1)]
            }

            for index in 8...11 {
                wires[index].scale = SIMD3<Float>(thickness, thickness, extent.z)
                wires[index].position = [extent.x / 2 * (index % 2 == 0 ? -1 : 1), extent.y / 2 * (index < 10 ? -1 : 1), 0]
            }
        }
    }
}
