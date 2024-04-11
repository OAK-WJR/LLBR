//
//  CameraView.swift
//  EL-UI
//
//  Created by WJR on 1/24/24.
//

import SwiftUI
import AVFoundation

struct CustomCameraView: View {
  @Binding var viewContent: BookEditContent
  
  @State var image: UIImage?
  @State var didTapCapture: Bool = false
  
  @State var showPicture: Bool = false
  
  @State var trashImage: Bool = false
  @State var showTrash: Bool = false
  var body: some View {
    ZStack(alignment: .center) {
      
      CustomCameraRepresentable(image: self.$image, didTapCapture: $didTapCapture)
        .ignoresSafeArea()
        .onSwipeGesture { direction in
          print(direction)
          if direction == .left {
            if let image = image {
              DispatchQueue.global(qos: .userInitiated).async {
                EditResourceDatabase().insertImage(image: image)
              }
            }
            withAnimation {
              viewContent = .edit
            }
          }
        }
      
      if let image = image {
        VStack {
          Spacer()
          HStack {
            ZStack {
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
              }
              
              if showTrash {
                Image(systemName: "trash")
                  .foregroundStyle(.red)
                  .frame(width: 20, height: 20)
                  .transition(.asymmetric(
                    insertion: .scale,
                    removal: .move(edge: .bottom)
                  ))
                  .padding(30)
              }
            }
            Spacer()
          }
          .background(Color.white.opacity(0.001))
          .onSwipeGesture { direction in
            print(direction)
            if direction == .down {
              withAnimation {
                showTrash = true
              }
              withAnimation(.easeInOut(duration: 1.0)) {
                trashImage = true
              }
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                  showTrash = false
                }
              }
            } else if direction == .left {
              DispatchQueue.global(qos: .userInitiated).async {
                EditResourceDatabase().insertImage(image: image)
              }
              viewContent = .edit
            }
          }
        }
        .onAppear {
          trashImage = false
          showTrash = false
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
                EditResourceDatabase().insertImage(image: image)
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
      // Screen size and aspect ratio
      let screenSize = UIScreen.main.bounds.size
      let screenAspectRatio = screenSize.width / screenSize.height
      
      // Original image size
      let originalSize = image.size
      let originalWidth = originalSize.height * screenAspectRatio
      
      let cropRect = CGRect(x: 0, y: (originalSize.width - originalWidth) / 2, width: originalSize.height, height: originalWidth)
      
      // Crop with CGImage
      guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return nil }
      let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
      
      return croppedImage
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
      
      parent.didTapCapture = false
      
      if let imageData = photo.fileDataRepresentation() {
        let croppedImage = cropImageToScreenSize(image: UIImage(data: imageData)!)
        parent.image = croppedImage
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
      
      let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
      captureSession.addInput(captureDeviceInput)
      photoOutput = AVCapturePhotoOutput()
      photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
      captureSession.addOutput(photoOutput!)
      
    } catch {
      print(error)
    }
    
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
