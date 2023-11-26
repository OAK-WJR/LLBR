//
//  OriginalEntry.swift
//  EL
//
//  Created by WJR on 11/10/23.
//

import SwiftUI
import AVFoundation
import UIKit

struct CameraView: View {
  @State var screen = UIScreen.main.bounds
  
  @State private var image: UIImage?
  @Binding var bookName: String
  @Binding var index: Int
  @Binding var ids: [Int]
  
  @State var startPoint: CGPoint?
  @State var direction: Direction = .none

  var body: some View {
    VStack {
      if let image = image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .onTapGesture(count: 2) {
            self.image = nil
          }
          .simultaneousGesture(
            DragGesture()
            .onChanged({ges in
              if startPoint == nil {
                startPoint = ges.location
              }
            })
            .onEnded({ ges in
              direction = handle(ges.location, startPoint!)
              if direction == .left {
                BooksDatabase().addOperation(image, in: bookName){ id in
                  DispatchQueue.global(qos: .userInitiated).async {
                    print("ID: \(id)")
                    ids = BooksDatabase().getAllIds(from: bookName)
                  }
                }
                self.image = nil
              }
              startPoint = nil
              direction = .none
            })
          )
      } else {
        CustomCameraView(image: $image, width: screen.width,
                                        height: screen.height)
        .ignoresSafeArea(.all)
        .overlay(
            VStack {
              Spacer()
              Rectangle()
                .fill(Color.white)
                .frame(height: 1)
            }
        )
      }
    }
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
      let zipedImage = OriginalProcessing.Photo().zipImage(image: image!)
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
    previewLayer?.videoGravity = .resizeAspectFill
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


//MARK: - UI interaction

func handle(_ nowPos: CGPoint, _ startPos: CGPoint) -> Direction {
  let dx = abs(nowPos.x - startPos.x)
  let dy = abs(nowPos.y - startPos.y)
  
  if startPos.y < nowPos.y && dy > dx {
    //Down
    return .down
  }
  else if startPos.y > nowPos.y && dy > dx {
    //up
    return .up
  }
  else if startPos.x < nowPos.x && dx > dy {
    //right
    return .right
  }
  else if startPos.x > nowPos.x && dx > dy {
    //left
    return .left
  } else {
    return .none
  }
}
