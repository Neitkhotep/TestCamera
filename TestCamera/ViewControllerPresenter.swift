//
//  ViewControllerPresenter.swift
//  TestCamera
//
//  Created by Ksenia on 03.05.2021.
//

import Foundation
import AVFoundation

protocol ViewControllerOutput: class {
    var onShowActivityIndicator: (Bool) -> () { get }
    var onShowError: (String) -> () { get }
    var onShare: (URL) -> () { get }
}

protocol ViewControllerInput: class where Self: AVCaptureFileOutputRecordingDelegate {
    func cleanup(_ outputFileURL: URL)
}

final class ViewControllerPresenter: NSObject, ViewControllerInput {
    var view: ViewControllerOutput?
    
    func cleanup(_ outputFileURL: URL) {
        let path = outputFileURL.path
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("Could not remove file at url: \(outputFileURL)")
            }
        }
    }
    
    private func encodeVideo(_ videoURL: URL)  {
        let avAsset = AVURLAsset(url: videoURL, options: nil)

        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough) else { return }

        view?.onShowActivityIndicator(true)
        
        DispatchQueue.global().async {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
            let filePath = documentsDirectory.appendingPathComponent("encoded-video.mp4")
            
            self.cleanup(filePath)

            exportSession.outputURL = filePath
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
            let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
            exportSession.timeRange = range

            exportSession.exportAsynchronously(completionHandler: { [weak self] () -> Void in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.view?.onShowActivityIndicator(false)
                    switch exportSession.status {
                    case .failed:
                        self.view?.onShowError(exportSession.error?.localizedDescription ?? "")
                    case .cancelled:
                        self.view?.onShowError("Export canceled")
                    case .completed:
                        if let url = exportSession.outputURL {
                            self.view?.onShare(url)
                        }
                    default:
                        break
                    }
                }
            })
        }
    }
}

extension ViewControllerPresenter: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print(fileURL)
    
    }
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        self.encodeVideo(outputFileURL)
    }
}
