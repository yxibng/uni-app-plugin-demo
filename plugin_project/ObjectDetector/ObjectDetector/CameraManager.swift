//
//  CameraManager.swift
//  CameraManager
//
//  Created by yxibng on 2025/3/29.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

func RunOnMainThread(block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}

@objc public protocol CameraManagerDelegate: NSObjectProtocol {
    func cameraManager(_ manager: CameraManager, didOutput pixelBuffer: CVPixelBuffer)
    func cameraManager(_ manager: CameraManager, didFailWithError error: Error)
    func cameraManagerDidStart(_ manager: CameraManager)
    func cameraManagerDidStop(_ manager: CameraManager)
}


public class CameraManagerPreviewView: UIView {
    
    lazy var detectionOverlay: CALayer = {
        let layer = CALayer()
        layer.name = "detectionOverlay"
        layer.bounds = self.bounds
        layer.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        return layer
    }()
    
    var isFrameChanged: Bool = false
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        isFrameChanged = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setup() {
        layer.addSublayer(detectionOverlay)
    }
    
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    func setSession(_ session: AVCaptureSession) {
        (layer as? AVCaptureVideoPreviewLayer)?.session = session
    }
    
    func setVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        (layer as? AVCaptureVideoPreviewLayer)?.connection?.videoOrientation = orientation
    }
    
    func setGravity(_ gravity: AVLayerVideoGravity) {
        (layer as? AVCaptureVideoPreviewLayer)?.videoGravity = gravity
    }
    
    func drawBoxes(_ boxes: [CGRect], pixelBuffer: CVPixelBuffer) {
        
        guard let layer = self.layer as? AVCaptureVideoPreviewLayer else {
            return
        }
        
        let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        if isFrameChanged || !CGSizeEqualToSize(CGSizeMake(imageWidth, imageHeight), self.detectionOverlay.bounds.size) {
            isFrameChanged = false
            self.detectionOverlay.bounds = CGRectMake(0, 0, imageWidth, imageHeight)
            self.detectionOverlay.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)

            var scale = 1.0
            let xScale = self.bounds.size.width / CGFloat(imageWidth)
            let yScale = self.bounds.size.height / CGFloat(imageHeight)
            
            if layer.videoGravity == .resizeAspectFill {
                //按比例填充
                scale = fmax(xScale, yScale)
            }
            
            if layer.videoGravity == .resizeAspect {
                scale = fmin(xScale, yScale)
                //按比例缩放
            }
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            self.detectionOverlay.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
            self.detectionOverlay.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            CATransaction.commit()
        }
        
        let subLayer = self.detectionOverlay.sublayers
        subLayer?.forEach { $0.removeFromSuperlayer() }
        if boxes.isEmpty {
            return
        }
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.clear.cgColor
        shapeLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        shapeLayer.bounds = self.detectionOverlay.bounds
        self.detectionOverlay.addSublayer(shapeLayer)
        shapeLayer.position = CGPoint(x: self.detectionOverlay.bounds.midX, y: self.detectionOverlay.bounds.midY)
        
        
        let backgroundPath = UIBezierPath(rect: shapeLayer.bounds)
        for box in boxes {
            backgroundPath.append(UIBezierPath(rect: box).reversing())
        }

        for box in boxes {
            let path = UIBezierPath()
            path.addCornerDecoration(rect: box, length: 10)

            let cornerLayer = CAShapeLayer()
            cornerLayer.path = path.cgPath
            cornerLayer.fillColor = UIColor.clear.cgColor
            cornerLayer.strokeColor = UIColor.blue.cgColor
            cornerLayer.lineWidth = 2
            cornerLayer.lineCap = .round
            self.detectionOverlay.addSublayer(cornerLayer)
        }
    
        shapeLayer.path = backgroundPath.cgPath
        
    }
}
    

public class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let captureSession = AVCaptureSession()
    // MARK: - 属性
    private var currentDevice: AVCaptureDevice?
    private var videoOutput = AVCaptureVideoDataOutput()
    private var isUsingFrontCamera = false
    
    private lazy var innerPreviewView: CameraManagerPreviewView = {
        let view = CameraManagerPreviewView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setSession(captureSession)
        view.setGravity(.resizeAspectFill)
        return view
    }()
    
    @objc public func drawBoxes(_ boxes: [CGRect], pixelBuffer: CVPixelBuffer) {
        RunOnMainThread {
            self.innerPreviewView.drawBoxes(boxes, pixelBuffer: pixelBuffer)
        }
    }

    @objc public weak var delegate: CameraManagerDelegate?
    
    @objc public var previewView: UIView? {
        didSet {
            RunOnMainThread {
                self.previewView?.addSubview(self.innerPreviewView)
                self.innerPreviewView.frame = self.previewView?.bounds ?? .zero
                self.innerPreviewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.previewView?.sendSubviewToBack(self.innerPreviewView)
            }
        }
    }
    
    private let processingQueue = DispatchQueue(label: "com.camera.processing.queue", qos: .userInitiated)
    private let sessionQueue = DispatchQueue(label: "com.camera.session.queue")

    @objc public override init() {
        super.init()
        setupSession()
        setupObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 核心方法
    @objc public  func startSession() {
        sessionQueue.async {
            guard !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            self.delegate?.cameraManagerDidStart(self)
        }
    }
    
    @objc public func stopSession() {
        sessionQueue.async {
            guard self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            self.delegate?.cameraManagerDidStop(self)
        }
    }
    
    @objc public func switchCamera(isFront: Bool) {
        sessionQueue.async {
            guard let currentInput = self.captureSession.inputs.first(where: { $0 is AVCaptureDeviceInput }) as? AVCaptureDeviceInput else { return }
            self.captureSession.beginConfiguration()
            do {
                self.captureSession.removeInput(currentInput)
                try self.addInputDevice(isFront: isFront)
                self.updateVideoOrientation()
                self.captureSession.commitConfiguration()
            } catch {
                self.captureSession.addInput(currentInput)
                print("切换摄像头失败: \(error)")
            }
        }
    }
    @objc public  func switchFlash(open: Bool) {
        sessionQueue.async {
            guard let captureDevice = self.currentDevice else { return }
            do {
                try captureDevice.lockForConfiguration()
                if captureDevice.hasTorch {
                    captureDevice.torchMode =  open ? .on : .off
                }
                captureDevice.unlockForConfiguration()
            } catch {
                print("切换手电筒失败: \(error)")
            }
        }
    }

    
   @objc public func setZoomLevel(_ level: Float) {
        if level > 10.0 || level < 0.0 {
            print("setZoomLevel failed, level should be in [0, 10]")
            return
        }
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            let zoomFactor = CGFloat(level / 10.0) * (device.maxAvailableVideoZoomFactor - device.minAvailableVideoZoomFactor) + device.minAvailableVideoZoomFactor
            
            print("level = \(level),zoomFactor: \(zoomFactor), min = \(device.minAvailableVideoZoomFactor), max = \(device.maxAvailableVideoZoomFactor)")
            
            
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = zoomFactor
                device.unlockForConfiguration()
            } catch {
                print("设置缩放失败: \(error)")
            }
        }
    }
    
    
    
    // MARK: - 私有方法
    private func setupSession() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            // 基础配置
            self.captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
            // 添加输入设备（默认后置摄像头）
            do {
                try self.addInputDevice(isFront: false)
            } catch {
                print("添加输入设备失败: \(error.localizedDescription)")
            }
            // 配置输出
            self.setupVideoOutput()
            self.captureSession.commitConfiguration()
        }
        

    }
    
    private func setFrameRate(device: AVCaptureDevice, minFPS: Double, maxFPS: Double) {
        do {
            try device.lockForConfiguration()
            
            // 计算帧间隔时间（单位：秒）
            let minFrameDuration = CMTimeMake(value: 1, timescale: Int32(minFPS))
            let maxFrameDuration = CMTimeMake(value: 1, timescale: Int32(maxFPS))
            
            // 设置帧率范围
            device.activeVideoMinFrameDuration = minFrameDuration
            device.activeVideoMaxFrameDuration = maxFrameDuration
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting frame rate: \(error)")
        }
    }
    
    private func setupVideoOutput() {
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            self.updateVideoOrientation()
        }
    }
    
    private func addInputDevice(isFront: Bool) throws {
        guard let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: isFront ? .front : .back).devices.first else {
            throw NSError(domain: "com.camera.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "未发现摄像头设备"])
        }
        let input = try AVCaptureDeviceInput(device: videoDevice)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            currentDevice = videoDevice
            setFrameRate(device: videoDevice, minFPS: 15, maxFPS: 30)
        } else {
            throw NSError(domain: "com.camera.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法添加摄像头设备"])
        }
    }
    
    private func updateVideoOrientation() {
        guard let connection = videoOutput.connection(with: .video) else { return }
        applyOrientation(for: connection)
    }
    
    private func applyOrientation(for connection: AVCaptureConnection) {
        guard let device = currentDevice else { return }
        
        let deviceOrientation = UIDevice.current.orientation
        let videoOrientation: AVCaptureVideoOrientation
        
        switch deviceOrientation {
        case .portrait:
            videoOrientation = .portrait
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            videoOrientation = .landscapeRight
        case .landscapeRight:
            videoOrientation = .landscapeLeft
        default:
            videoOrientation = .portrait
        }
        connection.videoOrientation = videoOrientation
        connection.isVideoMirrored = (device.position == .front)
        
        RunOnMainThread {
            self.innerPreviewView.setVideoOrientation(videoOrientation)
        }
    }
    
    // MARK: - 方向监听
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func deviceOrientationDidChange() {
        sessionQueue.async {
            guard let connection = self.videoOutput.connection(with: .video) else { return }
            self.applyOrientation(for: connection)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processFrame(sampleBuffer)
    }
    
    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        self.delegate?.cameraManager(self, didOutput: pixelBuffer)
    }
}
