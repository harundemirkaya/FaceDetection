//
//  ViewController.swift
//  FaceDetection
//
//  Created by Harun Demirkaya on 20.05.2023.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    // MARK: -Define
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    
    // MARK: -Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCameraInput()
        showCameraLayer()
        
        getCameraFrames()
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewLayer.frame = view.frame
    }
    
    // MARK: -Functions
    private func addCameraInput(){
        guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .front).devices.first else {
            fatalError("No camera detected. Please use a real camera, not a simulator.")
        }
        
        do{
            let cameraInput = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(cameraInput)
        } catch let error{
            fatalError(error.localizedDescription)
        }
    }
    
    private func showCameraLayer(){
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
    }
    
    private func getCameraFrames(){
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        
        captureSession.addOutput(videoDataOutput)
        
        guard let connection = videoDataOutput.connection(with: .video), connection.isVideoOrientationSupported else { return }
        
        connection.videoOrientation = .portrait
    }
    
    private func detectFace(image: CVPixelBuffer){
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { vnRequest, error in
            DispatchQueue.main.async {
                if let results = vnRequest.results as? [VNFaceObservation], results.count > 0{
                    print("Detected \(results.count) faces. Success :)")
                } else{
                    print("No face was detected")
                }
            }
        }
        
        let imageResultHander = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageResultHander.perform([faceDetectionRequest])
    }
}

// MARK: -AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("Unable to get image from sample buffer")
            return
        }
        
        detectFace(image: frame)
    }
}
