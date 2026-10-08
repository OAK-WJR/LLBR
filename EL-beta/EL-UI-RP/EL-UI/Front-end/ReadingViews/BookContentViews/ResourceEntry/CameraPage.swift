//
//  CameraView.swift
//  EL-UI
//
//  Created by WJR on 1/24/24.
//

import SwiftUI
import AVFoundation

struct CustomCameraView: View {
  @Binding var mainContent: ViewContent
  @Binding var viewContent: BookEditContent
  
  @State var image: UIImage?
  @State var didTapCapture: Bool = false
  
  @State var showPicture: Bool = false
  
  @State var trashImage: Bool = false
  
  @EnvironmentObject var CL: RE_ContentLoader
  var body: some View {
    ZStack(alignment: .center) {
      
      CustomCameraRepresentable(image: self.$image, didTapCapture: $didTapCapture)
        .ignoresSafeArea()
        .onSwipeGesture { direction in
          print(direction)
          if direction == .left {
            if let image = image {
              DispatchQueue.global(qos: .userInitiated).async {
                EditResourceDatabase().insertImage(image: image, atIndex: -1) {
                  CL.load()
                  self.image = nil
                  withAnimation {
                    viewContent = .edit
                  }
                }
              }
            } else {
              CL.load()
              if !CL.ids.isEmpty {
                withAnimation {
                  viewContent = .edit
                }
              }
            }
          } else if direction == .right {
            withAnimation {
              mainContent = .reading(.bookContent(.readPage))
            }
          }
        }
      
      if let image = image {
        VStack {
          Spacer()
          HStack {
            VStack {
              if !trashImage {
                Image(uiImage: image)
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .cornerRadius(5)
                  .frame(width: showPicture ? 50 : UIScreen.main.bounds.width)
                  .opacity(showPicture ? 0.5 : 1.0)
                  .shadow(radius: 15)
                  .transition(.asymmetric(
                    insertion: .move(edge: .top),
                    removal: .move(edge: .bottom)
                  ))
                  .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                      .stroke(.white, lineWidth: 1)
                      .opacity(showPicture ? 0.7 : 0)
                  )
                  .padding([.leading, .trailing], showPicture ? 10 : 0)
                  .onSwipeGesture { direction in
                    if direction == .down {
                      withAnimation {
                        trashImage = true
                      }
                    }
                  }
              }
            }
            Spacer()
          }
        }
        .onAppear {
          trashImage = false
          showPicture = false
          withAnimation(.easeInOut(duration: 0.3)) {
            showPicture = true
          }
        }
      }
      
      VStack {
        Spacer()
        HStack {
          Button(action: {
            if let image = image {
              DispatchQueue.global(qos: .userInitiated).async {
                EditResourceDatabase().insertImage(image: image, atIndex: -1) {}
              }
            }
            image = nil
            self.didTapCapture = true
          }) {
            Image(systemName: "circle")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 66, height: 66)
              .foregroundStyle(.white)
          }
        }
      }
      
    }
  }
}

struct CustomCameraRepresentable: UIViewControllerRepresentable {
  
  @Environment(\.presentationMode) var presentationMode
  @Binding var image: UIImage?
  @Binding var didTapCapture: Bool
  
  func makeUIViewController(context: Context) -> CustomCameraController {
    let controller = CustomCameraController()
    controller.delegate = context.coordinator
    return controller
  }
  
  func updateUIViewController(_ cameraViewController: CustomCameraController, context: Context) {
    
    if(self.didTapCapture) {
      cameraViewController.didTapRecord()
    }
  }
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
    let parent: CustomCameraRepresentable
    
    init(_ parent: CustomCameraRepresentable) {
      self.parent = parent
    }
    
    func cropImageToScreenSize(image: UIImage) -> UIImage? {
      let screenSize = UIScreen.main.bounds.size
      let screenAspectRatio = screenSize.width / screenSize.height
      
      let imageSize = image.size
      let realScreenSize = CGSize(width: imageSize.height * screenAspectRatio, height: imageSize.height)
      let scale = realScreenSize.width / imageSize.width
      
      let targetSize = CGSize(width: imageSize.width * scale, height: imageSize.height)
      print(targetSize)
      let croppedImage = image.centerCropped(to: targetSize)
      
      return croppedImage
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
      
      parent.didTapCapture = false
      
      if let imageData = photo.fileDataRepresentation() {
        if let image = UIImage(data: imageData) {
          let croppedImage = cropImageToScreenSize(image: image)
          let fixedImage = croppedImage!.fixOrientation()
          parent.image = fixedImage
        }
      }
      parent.presentationMode.wrappedValue.dismiss()
    }
  }
}

class CustomCameraController: UIViewController {
  
  var image: UIImage?
  
  var captureSession = AVCaptureSession()
  var backCamera: AVCaptureDevice?
  var frontCamera: AVCaptureDevice?
  var currentCamera: AVCaptureDevice?
  var photoOutput: AVCapturePhotoOutput?
  var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
  
  //DELEGATE
  var delegate: AVCapturePhotoCaptureDelegate?
  
  func didTapRecord() {
    
    let settings = AVCapturePhotoSettings()
    photoOutput?.capturePhoto(with: settings, delegate: delegate!)
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }
  func setup() {
    setupCaptureSession()
    setupDevice()
    setupInputOutput()
    setupPreviewLayer()
    startRunningCaptureSession()
  }
  func setupCaptureSession() {
    captureSession.sessionPreset = AVCaptureSession.Preset.photo
  }
  
  func setupDevice() {
    let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                  mediaType: AVMediaType.video,
                                                                  position: AVCaptureDevice.Position.unspecified)
    for device in deviceDiscoverySession.devices {
      
      switch device.position {
      case AVCaptureDevice.Position.front:
        self.frontCamera = device
      case AVCaptureDevice.Position.back:
        self.backCamera = device
      default:
        break
      }
    }
    
    self.currentCamera = self.backCamera
  }
  
  
  func setupInputOutput() {
    do {
      // Safely unwrap currentCamera
      if let camera = currentCamera {
        let captureDeviceInput = try AVCaptureDeviceInput(device: camera)
        captureSession.addInput(captureDeviceInput)
        photoOutput = AVCapturePhotoOutput()
        photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        captureSession.addOutput(photoOutput!)
      } else {
        // Handle the case where there is no camera
        print("没有可用的摄像头。")
        showCameraUnavailableAlert()
      }
    } catch {
      print("设置输入输出时发生错误: \(error)")
    }
  }

  func showCameraUnavailableAlert() {
    let alert = UIAlertController(title: "摄像头不可用", message: "没有可用的摄像头设备。请检查您的设备设置或使用其他功能。", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "确定", style: .default, handler: nil)
    alert.addAction(okAction)
    self.present(alert, animated: true, completion: nil)
  }

  func setupPreviewLayer() {
    self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
    self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
    self.cameraPreviewLayer?.frame = self.view.frame
    self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    
  }
  
  func startRunningCaptureSession() {
    DispatchQueue.global(qos: .userInitiated).async {
      self.captureSession.startRunning()
    }
  }
}

extension UIImage {
  func centerCropped(to newSize: CGSize) -> UIImage? {
    guard let cgImage = self.cgImage else { return nil }
    
    let contextSize = self.size
    
    let posX = (contextSize.width - newSize.width) / 2.0
    let posY = (contextSize.height - newSize.height) / 2.0
    let rect = CGRect(x: posY, y: posX, width: newSize.height, height: newSize.width)
    
    guard let croppedCGImage = cgImage.cropping(to: rect) else { return nil }
    
    return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
  }
}
