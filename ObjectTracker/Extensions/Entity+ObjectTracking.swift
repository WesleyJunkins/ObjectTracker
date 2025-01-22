//
//  Entity+ObjectTracking.swift
//  ObjectTracker
//
//  Created by Wesley Junkins on 9/20/24.
//
//  Extensions and utilities.
//

import RealityKit
import UIKit

/// Extension for the `Entity` class to provide utilities for creating text, axes, and applying materials.
extension Entity {
    
    /// Creates a 3D text entity with the specified string, height, and color.
    /// - Parameters:
    ///   - string: The text to display.
    ///   - height: The height of the text.
    ///   - color: The color of the text. Defaults to white.
    /// - Returns: A `ModelEntity` containing the 3D text.
    static func createText(_ string: String, height: Float, color: UIColor = .white) -> ModelEntity {
        // Define the font for the text.
        let font = MeshResource.Font(name: "Helvetica", size: CGFloat(height))!
        
        // Generate a 3D mesh for the text with a slight extrusion depth.
        let mesh = MeshResource.generateText(string, extrusionDepth: height * 0.05, font: font)
        
        // Create an unlit material with the specified color.
        let material = UnlitMaterial(color: color)
        
        // Create and return the text entity with the generated mesh and material.
        let text = ModelEntity(mesh: mesh, materials: [material])
        return text
    }

    /// Creates a set of 3D axes with the specified scale and transparency.
    /// - Parameters:
    ///   - axisScale: The scale of the axes.
    ///   - alpha: The transparency of the axes. Defaults to 1.0 (opaque).
    /// - Returns: An `Entity` containing the 3D axes.
    static func createAxes(axisScale: Float, alpha: CGFloat = 1.0) -> Entity {
        // Create the root entity for the axes.
        let axisEntity = Entity()

        // Generate a cube mesh for the axes.
        let mesh = MeshResource.generateBox(size: [1.0, 1.0, 1.0])

        // Create entities for the X, Y, and Z axes with different colors and transparency.
        let xAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1).withAlphaComponent(alpha))])
        let yAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1).withAlphaComponent(alpha))])
        let zAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1).withAlphaComponent(alpha))])

        // Add the axes entities as children of the root entity.
        axisEntity.children.append(contentsOf: [xAxis, yAxis, zAxis])

        // Define minor scale and position offsets for the axes.
        let axisMinorScale = axisScale / 20
        let axisAxisOffset = axisScale / 2.0 + axisMinorScale / 2.0

        // Set the positions and scales for the X, Y, and Z axes.
        xAxis.position = [axisAxisOffset, 0, 0]
        xAxis.scale = [axisScale, axisMinorScale, axisMinorScale]
        yAxis.position = [0, axisAxisOffset, 0]
        yAxis.scale = [axisMinorScale, axisScale, axisMinorScale]
        zAxis.position = [0, 0, axisAxisOffset]
        zAxis.scale = [axisMinorScale, axisMinorScale, axisScale]

        return axisEntity
    }
    
    /// Recursively applies a material to the entity and all its child entities.
    /// - Parameter material: The material to apply.
    func applyMaterialRecursively(_ material: RealityFoundation.Material) {
        // If the entity is a `ModelEntity`, apply the material to its model.
        if let modelEntity = self as? ModelEntity {
            modelEntity.model?.materials = [material]
        }
        
        // Recursively apply the material to all child entities.
        for child in children {
            child.applyMaterialRecursively(material)
        }
    }
}

