//
//  MainMenuVC.swift
//  rocketRush
//
//  Created by Aleksey Pirogov on 12.11.2023.
//

import UIKit

final class MainMenuVC: UIViewController {
    
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGradientBackground(button: startButton)
    }
}

// MARK: - MainMenuVC
private extension MainMenuVC {
    func setupGradientBackground(button: UIButton) {
        let gradientLayer = CAGradientLayer()
        print(button.bounds)
        gradientLayer.frame = button.bounds
        gradientLayer.colors = [
            UIColor(named: "gradient_1")!.cgColor,
            UIColor(named: "gradient_2")!.cgColor
            ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        // Устанавливаем градиентный слой как фон для кнопки
        button.layer.insertSublayer(gradientLayer, at: 0)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
    }
}
