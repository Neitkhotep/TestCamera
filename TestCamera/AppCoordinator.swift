//
//  AppCoordinator.swift
//  TestCamera
//
//  Created by Ksenia on 02.05.2021.
//
import Foundation
import UIKit

final class AppCoordinator {
    // MARK: Private Properties
    private let window: UIWindow
    private let navigationController: UINavigationController
    
    init(window: UIWindow, navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        self.window = window
        window.rootViewController = navigationController
    }
    
    func start() {
        showMain()
    }
    
    func showMain() {
        let presenter = ViewControllerPresenter()
        let vc = ViewController(presenter)
        presenter.view = vc
        navigationController.setViewControllers([vc], animated: false)
        navigationController.isNavigationBarHidden = true
    }
}
