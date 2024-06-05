//
//  Created by Aleksey Pirogov on 13.11.2023.
//

import UIKit

final class StatisticsVC: UIViewController {
    
    @IBOutlet weak var bestResultLabel: UILabel!
    @IBOutlet weak var lastResultLabel: UILabel!
    @IBOutlet weak var gamesPlayedLabel: UILabel!
    
    @IBOutlet weak var bestTitle: UILabel!
    @IBOutlet weak var lastTitle: UILabel!
    @IBOutlet weak var gamesTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bestResultLabel.font = UIFont(name: "Montserrat-BlackItalic", size: 150)
        bestResultLabel.textColor = UIColor(named: "gradient_2")
        lastResultLabel.font = UIFont(name: "Montserrat-BlackItalic", size: 50)
        lastResultLabel.textColor = UIColor(named: "total")
        gamesPlayedLabel.font = UIFont(name: "Montserrat-BlackItalic", size: 50)
        gamesPlayedLabel.textColor = UIColor.white

        bestTitle.font = UIFont(name: "Montserrat-BlackItalic", size: 20)
        lastTitle.font = UIFont(name: "Montserrat-BlackItalic", size: 20)
        gamesTitle.font = UIFont(name: "Montserrat-BlackItalic", size: 20)
        
        if let bestResult = UserDefaults.standard.value(forKey: "bestScore") as? Int {
            bestResultLabel.text = String(bestResult)
        }
        
        if let lastResult = UserDefaults.standard.value(forKey: "lastResult") as? Int {
            lastResultLabel.text = String(lastResult)
        }
        
        if let numberOfGames = UserDefaults.standard.value(forKey: "numberOfGames") as? Int {
            gamesPlayedLabel.text = String(numberOfGames)
        }
        
        let backButton = UIButton(type: .custom)
                backButton.setImage(UIImage(named: "back"), for: .normal)
                backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

                // Создаем кастомный UIBarButtonItem с кастомной кнопкой назад
                let customBackButton = UIBarButtonItem(customView: backButton)

                // Устанавливаем кастомный UIBarButtonItem в качестве кнопки назад
                self.navigationItem.leftBarButtonItem = customBackButton
        
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
}
