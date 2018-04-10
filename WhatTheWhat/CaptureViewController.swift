//
//  CaptureViewController.swift
//  WhatTheWhat
//
//  Created by Casey Barth on 4/10/18.
//  Copyright © 2018 Teeps. All rights reserved.
//

import AVKit
import UIKit
import Vision

final class CaptureViewController: UIViewController {
  @IBOutlet weak var captureView: UIView!
  @IBOutlet weak var vggIdentifierLabel: UILabel!
  @IBOutlet weak var resnetIdentifierLabel: UILabel!
  
  var vggLastCaptured: String = "" {
    didSet {
      DispatchQueue.main.async {
        self.vggIdentifierLabel.text = self.vggLastCaptured
      }
    }
  }
  var resnetLastCaptured: String = "" {
    didSet {
      DispatchQueue.main.async {
        self.resnetIdentifierLabel.text = self.resnetLastCaptured
      }
    }
  }
  
  lazy var captureSession: AVCaptureSession = {
    let capSession = AVCaptureSession()
    guard let capdevice = AVCaptureDevice.default(for: .video),
      let input = try? AVCaptureDeviceInput(device: capdevice) else { return capSession }
    capSession.addInput(input)
    return capSession
  }()
  
  var previewLayer: AVCaptureVideoPreviewLayer {
    let layer = AVCaptureVideoPreviewLayer(session: captureSession)
    layer.frame = captureView.bounds
    return layer
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureCapture()
    configureOutputMonitor()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    configureView()
  }
  
  private func configureCapture() {
    captureSession.startRunning()
  }
  
  private func configureView() {
    captureView.layer.addSublayer(previewLayer)
  }
  
  private func configureOutputMonitor() {
    let dataOutput = AVCaptureVideoDataOutput()
    captureSession.addOutput(dataOutput)
    dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
  }
}

extension CaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    
    guard let resnetRequest = generateRequest(forModel: .resnet),
      let vggRequest = generateRequest(forModel: .vgg16) else { return }
    
    try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([resnetRequest, vggRequest])
  }
  
  func generateRequest(forModel type: MLModelType) -> VNCoreMLRequest? {
    guard let model = type.model else { return nil }
    let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
      guard let results = finishedRequest.results as? [VNClassificationObservation],
      let firstObservation = results.first else { return }
      
      switch type {
      case .resnet: self.resnetLastCaptured = "RESNET: \(firstObservation.identifier)\nCONFIDENCE: \(firstObservation.confidence)"
      case .vgg16: self.vggLastCaptured = "VGG: \(firstObservation.identifier)\nCONFIDENCE: \(firstObservation.confidence)"
      }
    }
    
    return request
  }
}
