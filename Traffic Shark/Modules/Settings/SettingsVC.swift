//
//  SettingsVC.swift
//  rocketRush
//
//  Created by Aleksey Pirogov on 12.11.2023.
//

import UIKit
import StoreKit

final class SettingsVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.contentInset = .init(top: 32, left: 0, bottom: 0, right: 0)
        
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

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        56
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 2 : 4
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Notifications" : "General"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
        switch indexPath.section {
            
        case 0:
            
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "SettingsCheckBoxCell", for: indexPath) as? SettingsCheckBoxCell
            
            cell?.indexPath = indexPath
            cell?.delegate = self
            
            switch indexPath.row {
                
            case 0:
                cell?.title.text = "App Notifications"
                cell?.switchControl.isOn = UserDefaults.standard.bool(forKey: "settings.notifications.enabled")
            case 1:
                cell?.title.text = "Games Sounds"
                cell?.switchControl.isOn = UserDefaults.standard.bool(forKey: "settings.sounds.enabled")
            default:
                break
            }
            
            return cell ?? UITableViewCell()
            
        case 1:
            
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "SettingsSelectCell", for: indexPath) as? SettingsSelectCell
            let chevron = UIImage(named: "chevron")
            cell?.accessoryType = .disclosureIndicator
            cell?.accessoryView = UIImageView(image: chevron!)

            switch indexPath.row {
            case 0:
                cell?.title.text = "Privacy Policy"
            case 1:
                cell?.title.text = "Terms of Use"
            case 2:
                cell?.title.text = "Rate us"
            case 3:
                cell?.title.text = "Share app"
            default:
                break
            }
                        
            return cell ?? UITableViewCell()
            
        default: return UITableViewCell()
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.section == 1 else { return }
        
        switch indexPath.row {
            
        case 0:
            if let url = URL(string: "test.ru") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        case 1:
            if let url = URL(string: "test.ru") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        case 2:
            SKStoreReviewController.requestReview()
            
        case 3:
            let items = ["Traffic Shark"]
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
            
        default:
            break
        }
    }
}

extension SettingsVC: SettingsCheckBoxCellDelegate {
    
    func switcherDidSwitch(to value: Bool, indexPath: IndexPath) {
        
        switch indexPath.row {
            
        case 0:
            UserDefaults.standard.set(value, forKey: "settings.notifications.enabled")
        case 1:
            UserDefaults.standard.set(value, forKey: "settings.sounds.enabled")
        default: break
        }
    }
}
