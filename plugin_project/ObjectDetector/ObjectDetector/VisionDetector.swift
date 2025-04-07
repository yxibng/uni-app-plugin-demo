//
//  VisionDetector.swift
//  VehicleDetection
//
//  Created by yxibng on 2025/3/29.
//

import UIKit
import CoreML
import Vision

extension VNImageRequestHandler {
    convenience init?(uiImage: UIImage) {
        guard let ciImage = CIImage(image: uiImage) else { return nil }
        let orientation = uiImage.cgImageOrientation
        self.init(ciImage: ciImage, orientation: orientation)
    }
}

extension UIImage {
    func cropImage(toRect rect: CGRect) -> UIImage? {
        // 将裁剪区域从「UIImage坐标系」转换为「Core Graphics坐标系」
        let scale = self.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
        
        guard let cgImage = self.cgImage,
              let croppedCGImage = cgImage.cropping(to: scaledRect) else {
            return nil
        }
        
        return UIImage(
            cgImage: croppedCGImage,
            scale: self.scale,
            orientation: self.imageOrientation
        )
    }

}

extension UIBezierPath {
    
    func addCornerDecoration(rect: CGRect, length: CGFloat = 10) {
        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        
        //左上角
        self.move(to: CGPoint(x:topLeft.x + length, y: topLeft.y))
        self.addLine(to: topLeft)
        self.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y + length))
        
        
        //右上角
        self.move(to: CGPoint(x:topRight.x - length, y: topRight.y))
        self.addLine(to: topRight)
        self.addLine(to: CGPoint(x: topRight.x, y: topRight.y + length))
        
        //左下角向上
        self.move(to: CGPoint(x:bottomLeft.x, y: bottomLeft.y - length))
        self.addLine(to: bottomLeft)
        self.addLine(to: CGPoint(x: bottomLeft.x + length, y: bottomLeft.y))
        
        //右下角向左
        self.move(to: CGPoint(x:bottomRight.x - length, y: bottomRight.y))
        self.addLine(to: bottomRight)
        self.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y - length))
    }
    
    
}

@objc public protocol VisionDetectorDelegate: NSObjectProtocol {
    func onError(detector: VisionDetector, message: String)
    func onSuccess(detector: VisionDetector, objectBoxes: [CGRect], pixelBuffer: CVPixelBuffer)
    func onSuccess(detector: VisionDetector, annotedImage: UIImage, objectImages: [UIImage])
}

public class VisionDetector: NSObject {
    
    private var model: VNCoreMLModel?
    private let detectionQueue = DispatchQueue(label: "detectionQueue")

    @objc public weak var delegate: VisionDetectorDelegate?
    
    @objc public override init() {
        super.init()
        
        guard let url = Bundle.main.url(forResource: "yolov8n", withExtension: "mlmodelc") else {
            fatalError("Model file is missing")
        }
        
        guard let model = try? MLModel(contentsOf: url) else {
            fatalError("Model file is invalid")
        }
        if let model = try? VNCoreMLModel(for: model) {
            self.model = model
        } else {
            return
        }
    }

    @objc public func detect(pixelBuffer: CVPixelBuffer) {
        guard let model = self.model else { return }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            self?.handleResults(for: request, pixelBuffer: pixelBuffer, error: error)
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try imageRequestHandler.perform([request])
        } catch {
            delegate?.onError(detector: self, message: error.localizedDescription)
        }
    }
    
    func handleResults(for request: VNRequest, pixelBuffer: CVPixelBuffer,  error: Error?) {
        guard let observations = request.results as? [VNRecognizedObjectObservation] else { return }
        self.processDetectedObjects(observations, pixelBuffer: pixelBuffer)
    }
    
    func processDetectedObjects(_ observations: [VNRecognizedObjectObservation], pixelBuffer: CVPixelBuffer) {
        // Notify the delegate of the detected objects.
        let imageSize = CGSizeMake(CGFloat(CVPixelBufferGetWidth(pixelBuffer)), CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
        self.delegate?.onSuccess(detector: self, objectBoxes: observations.map { observation in
            let boundingBox = observation.boundingBox
            return convertBoundingBox(boundingBox, to: imageSize)
        }, pixelBuffer: pixelBuffer)
        
        //getnerate the annoted image
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        image.draw(at: .zero)
        if !observations.isEmpty {
            let excludePaths = observations.map { observation in
                let boundingBox = observation.boundingBox
                let rect = convertBoundingBox(boundingBox, to: image.size)
                return UIBezierPath(rect: rect).reversing()
            }
            let path = UIBezierPath(rect: CGRect(origin: .zero, size: image.size))
            for subPath in excludePaths {
                path.append(subPath)
            }
            UIColor.black.withAlphaComponent(0.5).setFill()
            path.fill()
        }
        
        for observation in observations {
            let boundingBox = observation.boundingBox
            let rect = convertBoundingBox(boundingBox, to: image.size)
            //draw corner
            let path = UIBezierPath()
            path.addCornerDecoration(rect: rect, length: 10)
            UIColor.blue.setStroke()
            path.lineWidth = 2
            path.lineCapStyle = .round
            path.stroke()
        }

        guard let markedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return
        }
        UIGraphicsEndImageContext()
        //get the object images
        let objectImages = observations.compactMap({ observation -> UIImage? in
            let boundingBox = observation.boundingBox
            let rect = convertBoundingBox(boundingBox, to: image.size)
            return image.cropImage(toRect: rect)
        })
        self.delegate?.onSuccess(detector: self, annotedImage: markedImage, objectImages: objectImages)

    }
    
    func convertBoundingBox(_ boundingBox: CGRect, to imageSize: CGSize) -> CGRect {
        let originY = 1 - boundingBox.origin.y - boundingBox.height
        return CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: originY * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
    }
    
}
extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch self.imageOrientation {
            case .up: return .up
            case .down: return .down
            case .left: return .left
            case .right: return .right
            case .upMirrored: return .upMirrored
            case .downMirrored: return .downMirrored
            case .leftMirrored: return .leftMirrored
            case .rightMirrored: return .rightMirrored
        @unknown default:
            return .up
        }
    }
}
