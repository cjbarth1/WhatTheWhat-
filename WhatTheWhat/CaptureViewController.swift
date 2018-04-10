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
    captureView.layer.cornerRadius = 5.0
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
    
    guard let resnetModel = try? VNCoreMLModel(for: Resnet50().model),
      let VGModel = try? VNCoreMLModel(for: VGG16().model) else { return }
    
    let resnetRequest = VNCoreMLRequest(model: resnetModel) { (finishedRequest, error) in
      guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
      guard let firstObservation = results.first else { return }
      self.resnetLastCaptured = "RESNET: \(firstObservation.identifier)\nCONFIDENCE: \(firstObservation.confidence)"
    }
    
    let VGRequest = VNCoreMLRequest(model: VGModel) { (finishedRequest, error) in
      guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
      guard let firstObservation = results.first else { return }
      self.vggLastCaptured = " VGG: \(firstObservation.identifier)\nCONFIDENCE: \(firstObservation.confidence)"
    }
    
    try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([resnetRequest])
    try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([VGRequest])
    
  }
}
