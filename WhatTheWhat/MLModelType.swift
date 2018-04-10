//
//  MLModelType.swift
//  WhatTheWhat
//
//  Created by Casey Barth on 4/10/18.
//  Copyright © 2018 Teeps. All rights reserved.
//

import Vision
import UIKit

enum MLModelType {
  case vgg16
  case resnet
  
  var model: VNCoreMLModel? {
    switch self {
    case .vgg16: return try? VNCoreMLModel(for: VGG16().model)
    case .resnet: return try? VNCoreMLModel(for: Resnet50().model)
    }
  }
}
