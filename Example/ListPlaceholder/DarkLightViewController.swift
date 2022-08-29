//
//  DarkLightViewController.swift
//  Example
//
//  Created by Chung Tran on 07/07/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class DarkLightViewController: UIViewController {
    @IBOutlet var stackView: UIStackView!
    var mode: UIUserInterfaceStyle = .light {
        didSet {
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = mode
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white.onDarkMode(UIColor(hex: "#16172A"))
        stackView.showLoader()
    }

    @IBAction func changeModeButtonDidTouch(_ sender: Any) {
        mode = mode == .dark ? .light : .dark
    }

    private var userInterfaceStyle: UIUserInterfaceStyle = UITraitCollection.current.userInterfaceStyle

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let currentUserInterfaceStyle = UITraitCollection.current.userInterfaceStyle
        guard currentUserInterfaceStyle != userInterfaceStyle else { return }
        userInterfaceStyle = currentUserInterfaceStyle
        NotificationCenter.default.post(name: Notification.Name("trait_collection_style_changed"), object: nil)
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}

@available(iOS 13.0, *)
private extension UIColor {
    func onDarkMode(_ color: UIColor) -> UIColor {
        let lightColor = self
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? color : lightColor
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int & 0xFF, int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(displayP3Red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
