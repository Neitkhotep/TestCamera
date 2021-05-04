//
//  ViewController.swift
//  TestCamera
//
//  Created by Ksenia on 02.05.2021.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            DispatchQueue.main.async {
                self.videoPreviewLayer.session = newValue
            }
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}

private enum SessionSetupResult {
    case none
    case success
    case notAuthorized
    case configurationFailed
    
    var errorMessage: String? {
        switch self {
       
        case .none:
            return "Not determoned"
        case .success:
            return nil
        case .notAuthorized:
            return "Authorization failed"
        case .configurationFailed:
            return "Configuration failed"
        }
    }
}

class ViewController: UIViewController, ViewControllerOutput {
  
    lazy var onShowError: (String) -> () = { [weak self] message in
        self?.showError(message)
    }
    
    lazy var onShowActivityIndicator: (Bool) -> () = { [weak self] show in
        show ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
        self?.activityIndicator.isHidden = !show
        self?.view.isUserInteractionEnabled = !show
    }
    
    lazy var onShare: (URL) -> () = { [weak self] url in
        self?.share(url)
    }

    private let session = AVCaptureSession()
    private let activityIndicator = UIActivityIndicatorView()
    private let previewView = PreviewView()
    private let presenter: ViewControllerInput
    
    private var sessionSetupResult: SessionSetupResult = .none
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    private lazy var button: PulsatingButton = {
        let btn = PulsatingButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = .white
        btn.addTarget(self, action: #selector(tapped(sender:)), for: UIControl.Event.touchUpInside)
        return btn
    }()
    
    init(_ presenter: ViewControllerInput) {
        self.presenter = presenter

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkAuthorization()
    }
    
    override func loadView() {
        view = UIView()
        setupViews()
    }
    
    @objc
    func tapped(sender: Any) {
        guard sessionSetupResult == .success else {
            showError(sessionSetupResult.errorMessage)
            return
        }
        
        if movieFileOutput!.isRecording {
            button.stopPulsation()
            onFinish()
        } else {
            button.startPulsatiion()
            onStartRecording()
        }
    }
    
    func share(_ outputFileURL: URL) {
          let videoURL = outputFileURL

          let activityItems: [Any] = [videoURL, "Share video"]
          let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

          activityController.popoverPresentationController?.sourceView = view
          activityController.popoverPresentationController?.sourceRect = view.frame
          activityController.completionWithItemsHandler = { [weak self] activityType, completed, _, error in
            self?.presenter.cleanup(outputFileURL)
    
            guard let error = error else { return }
            
            self?.showError(error.localizedDescription)
          }

          self.present(activityController, animated: true, completion: nil)
    }
    
    private func checkAuthorization() {
        func onAuthorizationFailed() {
            DispatchQueue.main.async {
                self.sessionSetupResult = .notAuthorized
                self.showError(self.sessionSetupResult.errorMessage)
            }
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    onAuthorizationFailed()
                    return
                }
                self.setupSession()
            })
            
        default:
            onAuthorizationFailed()
        }
    }
    
    private func onStartRecording() {
        
        focus(with: .autoFocus, exposureMode: .autoExpose, whiteBalanceMode: .autoWhiteBalance)
       
        let outputFileName = NSUUID().uuidString
        let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
        movieFileOutput?.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: presenter)
    }
   
    private func showError(_ message: String?) {
        guard let message = message else { return }
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK",
                                                style: .cancel,
                                                handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
  
    private func  onFinish() {
        movieFileOutput?.stopRecording()
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode) {
        
        DispatchQueue.global().async {
            guard let device = self.videoDeviceInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusModeSupported(focusMode) {
                    device.focusMode = focusMode
                }
                
                if device.isWhiteBalanceModeSupported(whiteBalanceMode)  {
                    device.whiteBalanceMode = whiteBalanceMode
                }
                
                if device.isExposureModeSupported(exposureMode) {
                    device.exposureMode = exposureMode
                }
                
                device.activeMaxExposureDuration = CMTime(value: 1, timescale: 100)
                
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    private func setupViews() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.style = .large
        
        view.addSubview(previewView)
        view.addSubview(button)
        view.addSubview(activityIndicator)
        activityIndicator.isHidden = true
        button.layer.cornerRadius = 25.0
        NSLayoutConstraint.activate([
            previewView.rightAnchor.constraint(equalTo: view.rightAnchor),
            previewView.leftAnchor.constraint(equalTo: view.leftAnchor),
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func setupSession() {
        DispatchQueue.global().async {
            self.session.beginConfiguration()
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                            for: .video,
                                                            position: .back),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoDeviceInput) else {
                self.sessionSetupResult = .configurationFailed
                return
            }
            
            self.videoDeviceInput = videoDeviceInput
            self.session.addInput(videoDeviceInput)
            
            let movieFileOutput = AVCaptureMovieFileOutput()
            
            guard self.session.canAddOutput(movieFileOutput) else {
                self.sessionSetupResult = .configurationFailed
                return
            }
            
            self.movieFileOutput = movieFileOutput
            self.session.addOutput(movieFileOutput)
            self.session.sessionPreset = .high
            
            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            
            self.session.commitConfiguration()
            self.session.startRunning()
            
            self.previewView.session = self.session
            self.sessionSetupResult = .success
        }
    }
}
