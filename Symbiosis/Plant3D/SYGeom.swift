//
////
////  ShapeMaker.swift
////  POC-SceneKit
////
////  Created by Etienne De Ladonchamps on 25/02/2016.
////  Copyright © 2016 Etienne De Ladonchamps. All rights reserved.
////

import Foundation
import SceneKit
import GLKit


/**
 * Class that generate a geometry and a material
 **/
class SYGeom {
    
    var totalBoneSize: Float = 0.0
    var bones: [SYBone] = []
    var steps: [SYStep] = []
    var faces: [[SYFace]] = []
    var materials: [SCNMaterial] = []
    var props: Any
    var geometry: SCNGeometry?
    let parent: SYRederable
    
    init (props: Any, parent: SYRederable) {
        self.props = props
        self.parent = parent
        
        verifyProps()
        
        self.generateBones()
        self.generateSteps()
        self.generateMaterial()
    }
    
    
    init (withoutGenerateWithProps props: Any, parent: SYRederable) {
        self.props = props
        self.parent = parent
        
        verifyProps()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func generateGeometry() {
        self.createFaces()
        let geomData = self.getGeometryData()
        self.geometry = SCNGeometry(sources: [geomData.normalSource, geomData.vertexSource], elements: geomData.elements)
        self.geometry!.materials = self.materials
    }
    
    private func generateBones () {
        
        var isLastStep: Bool = false
        var stepIndex: Int = 0;
        var boneSizeFromStart: Float = 0.0

        // Run boneFunc
        repeat {
            // Create options struct
            let options = SYBoneFuncOptions(
                bones: self.bones,
                index: stepIndex,
                boneSizeFromStart: boneSizeFromStart
            )
            // Exec func
            var bone = self.boneFunc(options)
            // set index
            bone.index = stepIndex
            // set sizeFromStart
            bone.sizeFromStart = boneSizeFromStart + bone.size
            // Append the bone
            self.bones.append(bone);
            
            isLastStep = bone.isLastStep
            
            boneSizeFromStart += bone.size
            
            if (!isLastStep) {
                stepIndex += 1
            }
//            else {
//                //last step
//            }
            
        } while (!isLastStep)
        
        // Resolve bone's positions and rotation
        self.resolveBonesPositionsAndRotations()
        
        self.totalBoneSize = boneSizeFromStart
    }
    
    private func generateSteps () {
        
        for bone in self.bones {
            // Create options
            let options = SYStepFuncOptions(
                bone: bone,
                nbrOfSteps: self.bones.count,
                totalBoneSize: self.totalBoneSize
            )
            // Exec func
            var step = self.stepFunc(options)
            // set index
            step.index = bone.index
            step.bone = bone
            self.steps.append(step)
        }
        
        self.resolveStepsPositionsAndRotations()
        
    }
    
    private func resolveBonesPositionsAndRotations() {
        var bonePosition: GLKVector3 = GLKVector3Make(0, 0, 0)
        var boneRotation: GLKMatrix4 = GLKMatrix4MakeRotation(0, 0, 1, 0)
        for i in 0 ..< self.bones.count {
            let bone: SYBone = self.bones[i]
            
            if bone.isAbsolute == false {
                // Apply bone
                var boneTranslationAfterRotation: GLKVector3 = GLKMatrix4MultiplyAndProjectVector3(bone.orientation, bone.translation)
                boneTranslationAfterRotation = GLKMatrix4MultiplyAndProjectVector3(boneRotation, boneTranslationAfterRotation)
                bonePosition = GLKVector3Add(bonePosition, boneTranslationAfterRotation)
                boneRotation = GLKMatrix4Multiply(boneRotation, bone.orientation)
            } else {
                bonePosition = bone.translation
                boneRotation = bone.orientation
            }
            self.bones[i].rotation = boneRotation
            self.bones[i].position = bonePosition

        }
    }
    
    private func resolveStepsPositionsAndRotations () {
        for i in 0 ..< self.bones.count {
            let bone: SYBone = self.bones[i]
            var step: SYStep = self.steps[i]
            
            // Convert step points
            for j in 0 ..< step.points.count {
                let point: GLKVector3 = step.points[j]
                let rotatedPoint: GLKVector3 = GLKMatrix4MultiplyAndProjectVector3(bone.rotation, point)
                self.steps[i].points[j] = GLKVector3Add(bone.position, rotatedPoint)
            }
        }
    }
    
    private func createFaces () {
        
        if self.steps.count == 0 {
            // print("No steps :/")
            return
        }
        
        for index in 0 ..< self.steps.count-1 {
            let step = self.steps[index]
            let nextStep = self.steps[index+1]
            
            var leftIndex = 0
            var rightIndex = 0
            
            var stepFaces: [SYFace] = []
            
            var nbrOfFaces = step.count + nextStep.count
            if step.count == 1 {
                nbrOfFaces -= 1
            }
            if nextStep.count == 1 {
                nbrOfFaces -= 1
            }
            nbrOfFaces -= 1
            
            
            if (nbrOfFaces < 0) {
                nbrOfFaces = 0
            }
            
            for _ in 0...nbrOfFaces {
                var points: [GLKVector3] = []
                points.append(step.points[leftIndex % step.count])
                points.append(nextStep.points[rightIndex % nextStep.count])
                
                let nextLeftInterpolate = Float(leftIndex+1) / Float(step.count+1)
                let nextRightInterpolate = Float(rightIndex+1) / Float(nextStep.count+1)
                
                var useLeft: Bool
                if leftIndex == step.count - 1 && rightIndex < nextStep.count - 1 {
                    useLeft = false
                } else if leftIndex < step.count - 1 && rightIndex == nextStep.count - 1 {
                    useLeft = true
                } else if leftIndex == step.count - 1 && rightIndex == nextStep.count - 1 {
                    if step.count == 1 {
                        useLeft = false
                    } else
                        if nextStep.count == 1 {
                            useLeft = true
                        } else {
                            useLeft = true
                    }
                } else {
                    useLeft = nextLeftInterpolate <= nextRightInterpolate
                }
                
                if (useLeft) {
                    leftIndex += 1
                    points.append(step.points[leftIndex % step.count])
                } else {
                    rightIndex += 1
                    points.append(nextStep.points[rightIndex % nextStep.count])
                }
                
                stepFaces += [SYFace(points: points)]
            }
            
            self.faces += [stepFaces]
        }
    }
    
    
    private func getGeometryData () -> (vertexSource: SCNGeometrySource, normalSource: SCNGeometrySource, elements: [SCNGeometryElement]) {
        
        var verticesList = [GLKVector3]()
        var indicesList = [Int]()
        var normalsList = [GLKVector3]()
        
        for stepFaces in self.faces {
            for face in stepFaces {
                let originPoint = face.points[0]
                let firstPoint = face.points[2]
                let secondPoint = face.points[1]
                let firstVector = GLKVector3Subtract(firstPoint, originPoint)
                let secondVector = GLKVector3Subtract(secondPoint, originPoint)
                var normal = GLKVector3CrossProduct(firstVector, secondVector)
                normal = GLKVector3Normalize(normal)
                
                // First point
                let verticeIndex = verticesList.count
                verticesList += [originPoint]
                normalsList += [normal]
                indicesList += [verticeIndex]
                
                // Second point
                //                verticeIndex = verticesList.count
                verticesList += [firstPoint]
                normalsList += [normal]
                indicesList += [verticeIndex+1]
                
                // Third point
                //                verticeIndex = verticesList.count
                verticesList += [secondPoint]
                normalsList += [normal]
                indicesList += [verticeIndex+2]
            }
        }
        
        let verticesCount = verticesList.count
        let normalsCount = normalsList.count
        let indicesCount = indicesList.count
        
        // totalVerticeCount += verticesCount
        // print(totalVerticeCount)
        
        if (normalsCount != verticesCount) {
            fatalError("normalsCount !== verticesCount : %i !== %i -- normalsCount : \(normalsCount) - verticesCount : \(verticesCount)")
        }
        
        let positions :[SCNVector3] = verticesList.map { (vertice) -> SCNVector3 in
            return SCNVector3FromGLKVector3(vertice)
        }
        
        let normals :[SCNVector3] = normalsList.map { (norm) -> SCNVector3 in
            return SCNVector3FromGLKVector3(norm)
        }
        
        let indices :[CInt] = indicesList.map { (indi) -> CInt in
            return CInt(indi)
        }
        
        // Create sources for the vertices and normals
        let vertexSource = SCNGeometrySource(vertices:positions, count:verticesCount)
        let normalSource = SCNGeometrySource(normals:normals, count:normalsCount)
        
        let indexData = NSData(
            bytes:indices,
            length: (indices.count * sizeof(CInt))
        )
        
        let element = SCNGeometryElement(
            data:indexData,
            primitiveType:SCNGeometryPrimitiveType.Triangles,
            primitiveCount:indicesCount/3,
            bytesPerIndex: sizeof(CInt)
        )
        
        return (vertexSource, normalSource, [element])
    }
    
    func getBones() -> [SYBone] {
        if self.bones.count == 0 {
            self.generateBones()
        }
        return self.bones
    }
    
    
    // MARK: Default generate func
    
    func verifyProps() {}
    
    func boneFunc (options: SYBoneFuncOptions) -> SYBone {
        var isLastStep: Bool = false
        let nbrOfSteps = 5
        let size = 2 / Float(nbrOfSteps)
        if (options.index == nbrOfSteps) {
            isLastStep = true
        }
        
        let translation: GLKVector3 = GLKVector3Make(0, size, 0)
        let orientation: GLKMatrix4 = GLKMatrix4MakeRotation(0, 0, 1, 0)
        
        return SYBone(translation: translation, orientation: orientation, size: nil, isLastStep: isLastStep, isAbsolute: nil)
    }
    
    func stepFunc (options: SYStepFuncOptions) -> SYStep {
        let progress: Float = options.bone.sizeFromStart! / options.totalBoneSize

        var points: [GLKVector3] = []
        
        // Last step
        if progress == 1 {
            points.append(GLKVector3Make(0, 0, 0))
        } else
            if progress == 0 {
                points.append(GLKVector3Make(0.25, 0, 0))
                points.append(GLKVector3Make(-0.25, 0, 0))
            } else
                if progress == 0.6 {
                    points.append(GLKVector3Make(0.5, 0, 0.5))
                    points.append(GLKVector3Make(0.5, 0, -0.5))
                    points.append(GLKVector3Make(-0.5, 0, -0.5))
                } else{
                    points.append(GLKVector3Make(0.5, 0, 0.5))
                    points.append(GLKVector3Make(0.5, 0, -0.5))
                    points.append(GLKVector3Make(-0.5, 0, -0.5))
                    points.append(GLKVector3Make(-0.5, 0, 0.5))
        }
        
        return SYStep(points: points)
    }
    
    func generateMaterial() {
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.blueColor()
        mat.doubleSided = true
        
        self.materials = [mat]
    }
    
    
    
}