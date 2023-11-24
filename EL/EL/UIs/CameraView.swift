//
//  OriginalEntry.swift
//  EL
//
//  Created by WJR on 11/10/23.
//

import SwiftUI
import AVFoundation
import UIKit

let screen = UIScreen.main.bounds
struct OriginalPhotosView: View {
  @State private var image: UIImage?
  @State var tableName: String = "diary"
  @State var pageNow: Any? = nil
  
  @State var photoRatio: CGFloat = 16/9

  var body: some View {
    VStack {
      if let image = image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .edgesIgnoringSafeArea(.all)
          .onAppear {
            BooksDatabase().addOperation(image, in: tableName) { page in
              pageNow = page
              print(pageNow ?? "-1")
            }
          }

      } else {
        CustomCameraView(image: $image, width: screen.width, height: screen.width * photoRatio)
          .edgesIgnoringSafeArea(.all)
          .frame(height: screen.width * photoRatio)
          .border(.green)
      }
    }
    .border(.blue)
  }
}

//MARK: - Camera view

struct CustomCameraView: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  var width: CGFloat
  var height: CGFloat
  @Environment(\.presentationMode) var presentationMode

  func makeUIViewController(context: Context) -> CustomCameraViewController {
    let viewController = CustomCameraViewController()
    viewController.delegate = context.coordinator
    viewController.width = width
    viewController.height = height
    return viewController
  }

  func updateUIViewController(_ uiViewController: CustomCameraViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, CustomCameraViewControllerDelegate {
    let parent: CustomCameraView

    init(_ parent: CustomCameraView) {
      self.parent = parent
    }

    func didTakePhoto(_ image: UIImage?) {
      let zipedImage = OriginalProcessing.Photo.processImage(image: image!)
      parent.image = zipedImage
      parent.presentationMode.wrappedValue.dismiss()
    }
  }
}

//MARK: - Camera controller
protocol CustomCameraViewControllerDelegate: AnyObject {
  func didTakePhoto(_ image: UIImage?)
}

class CustomCameraViewController: UIViewController {
  weak var delegate: CustomCameraViewControllerDelegate?
  var captureSession: AVCaptureSession?
  var photoOutput: AVCapturePhotoOutput?
  var previewLayer: AVCaptureVideoPreviewLayer?
  
  var width: CGFloat = 0
  var height: CGFloat = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setupCamera()
    setupDoubleTapGesture()
  }

  func setupCamera() {
    captureSession = AVCaptureSession()
    guard let captureSession = captureSession else { return }

    photoOutput = AVCapturePhotoOutput()
    guard let photoOutput = photoOutput,
          let backCamera = AVCaptureDevice.default(for: .video) else { return }

    do {
        let input = try AVCaptureDeviceInput(device: backCamera)
        if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
            captureSession.addInput(input)
            captureSession.addOutput(photoOutput)
            setupPreviewLayer(session: captureSession)
        }
    } catch {
        print("Error setting up camera input: \(error)")
    }

    captureSession.startRunning()
  }

  func setupPreviewLayer(session: AVCaptureSession) {
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer?.videoGravity = .resizeAspect // keep the aspect ratio
    let bounds = view.layer.bounds
    let width = bounds.width
    let height = width * 16 / 9 // 16:9 aspect ratio
    previewLayer?.frame = CGRect(x: 0, y: 0, width: width, height: height)
    view.layer.addSublayer(previewLayer!)
  }

  func setupDoubleTapGesture() {
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
    doubleTapGesture.numberOfTapsRequired = 2
    view.addGestureRecognizer(doubleTapGesture)
  }

  @objc func handleDoubleTap() {
    let settings = AVCapturePhotoSettings()
    photoOutput?.capturePhoto(with: settings, delegate: self)
  }
}

extension CustomCameraViewController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageData = photo.fileDataRepresentation() else { return }
    let image = UIImage(data: imageData)
    delegate?.didTakePhoto(image)
  }
}
