//
//  Created by Aleksey Pirogov on 12.11.2023.
//

import UIKit

protocol SettingsCheckBoxCellDelegate: AnyObject {
    func switcherDidSwitch(to value: Bool, indexPath: IndexPath)
}

final class SettingsCheckBoxCell: UITableViewCell {
    
    weak var delegate: SettingsCheckBoxCellDelegate?
    
    var indexPath: IndexPath?
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var switchControl: UISwitch!
    
    @IBAction func switchControl(_ sender: UISwitch) {
        guard let indexPath else { return }
        delegate?.switcherDidSwitch(to: sender.isOn, indexPath: indexPath)
    }
}

