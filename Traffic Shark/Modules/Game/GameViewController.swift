//
//  Created by Aleksey Pirogov on 6/2/14.
//

import UIKit
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(_ file : String) -> SKNode? {
        
        let path = Bundle.main.path(forResource: file, ofType: "sks")
        
        let sceneData: Data?
        do {
            sceneData = try Data(contentsOf: URL(fileURLWithPath: path!), options: .mappedIfSafe)
        } catch _ {
            sceneData = nil
        }
        let archiver = NSKeyedUnarchiver(forReadingWith: sceneData!)
        
        archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
        let scene = archiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! GameScene
        archiver.finishDecoding()
        return scene
    }
}

class GameViewController: UIViewController {

    @IBOutlet weak var resultView: UIView!
    @IBOutlet weak var mainMenuButton: UIButton!
    @IBOutlet weak var newGameButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var bestResultLabel: UILabel!
    @IBOutlet weak var counterView: UIView!
    @IBOutlet weak var counterLabel: UIImageView!
    @IBOutlet weak var resultTitle: UILabel!
    @IBOutlet weak var bestTitle: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    
    var countdownTimer: Timer?
    var countdownValue = 3
    
    var scene: GameScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = true

        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .aspectFill
            
            scene.sceneDelegate = self
            
            self.scene = scene
            
            skView.presentScene(scene)
            
            let overlay = UIView()
            overlay.backgroundColor = UIColor(named: "result_back")

            // Размер и расположение блюра
            overlay.frame = view.bounds
            overlay.alpha = 0.9
            
//            blurView.contentView.addSubview(createBlurredImage()) // Вызываем функцию для создания размытого изображения

            // Добавляем блюр на представление
            resultView.insertSubview(overlay, at: 0)
            
            resultTitle.font = UIFont(name: "Montserrat-BlackItalic", size: 20)
            resultTitle.textColor = UIColor.white
            
            resultLabel.font = UIFont(name: "Montserrat-BlackItalic", size: 150)
            resultLabel.textColor = UIColor(named: "gradient_1")
            
            bestTitle.font = UIFont(name: "Montserrat-Black", size: 20)
            bestTitle.textColor = UIColor.white

            bestResultLabel.font = UIFont(name: "Montserrat-BlackItalic", size: 50)
            bestResultLabel.textColor = UIColor(named: "total")
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setGradientBackground(button: mainMenuButton)
        setGradientBackground(button: newGameButton)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
            
    func setGradientBackground(button: UIButton) {
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

    override var shouldAutorotate : Bool {
        return true
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIInterfaceOrientationMask.allButUpsideDown
        } else {
            return UIInterfaceOrientationMask.all
        }
    }
    
    @IBAction func tapMainMenu(_ sender: Any) {
        scene?.endGame()
        self.navigationController?.popViewController(animated: true)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    @IBAction func tapNewGame(_ sender: Any) {
        resultView.isHidden = true
        scene?.resetGameScene()
        countdownValue = 3
        counterLabel.image = UIImage(named: "counter_\(countdownValue)")
        counterView.isHidden = false
        startCountdown()
    }
    
    @IBAction func tapPause(_ sender: Any) {
        guard let isPaused = scene?.isPaused else { return }
        scene?.isPaused = !isPaused
    }
}

// MARK: - GameSceneDelegate
extension GameViewController: GameSceneDelegate {
    func scenePaused(_ value: Bool) {
        pauseButton.setImage(value ? .init(named: "play") : .init(named: "pause"), for: .normal)
    }
    
    func displayCounter() {
        countdownValue = 3
        counterView.isHidden = false
        startCountdown()
    }
    
    func startCountdown() {
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
    }
    
    @objc func updateCountdown() {
        if countdownValue > 1 {
            countdownValue -= 1
            counterLabel.image = UIImage(named: "counter_\(countdownValue)")
        } else {
            countdownTimer?.invalidate()
            counterView.isHidden = true
            scene?.isPaused = false
        }
    }

    func gameEnded(score: Int) {
        scene?.isPaused = true
        self.resultLabel.text = String(score)
        if let bestScore = UserDefaults.standard.value(forKey: "bestScore") as? Int {
            self.bestResultLabel.text = String(bestScore)
        } else {
            self.bestResultLabel.text = String(score)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            UIView.transition(with: resultView, duration: 0.3, options: .transitionCrossDissolve) {
                self.resultView.isHidden = false
            }
        }
    }
}
