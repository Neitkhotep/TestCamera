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
    
}

extension ViewControllerPresenter: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print(fileURL)
    
    }
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
       
    }
}
