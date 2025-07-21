//
//  UIView extension.swift
//  ListPlaceholder
//
//  Created by Ruben Nahatakyan on 23.08.22.
//

import UIKit

// TODO: - Allow caller to tweak these
var cutoutHandle: UInt8 = 0
var gradientHandle: UInt8 = 0
var loaderDuration = 0.85
var gradientWidth: Double = 0.17
var gradientFirstStop: Double = 0.1

extension UIView {
    func ld_getCutoutView() -> UIView? {
        return objc_getAssociatedObject(self, &cutoutHandle) as! UIView?
    }

    func ld_setCutoutView(_ aView: UIView) {
        return objc_setAssociatedObject(self, &cutoutHandle, aView, .OBJC_ASSOCIATION_RETAIN)
    }

    func ld_getGradient() -> CAGradientLayer? {
        return objc_getAssociatedObject(self, &gradientHandle) as! CAGradientLayer?
    }

    func ld_setGradient(_ aLayer: CAGradientLayer) {
        return objc_setAssociatedObject(self, &gradientHandle, aLayer, .OBJC_ASSOCIATION_RETAIN)
    }

    func ld_addLoader(coverColor: UIColor) {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
        self.layer.insertSublayer(gradient, at: 0)

        self.configureAndAddAnimationToGradient(gradient)
        self.addCutoutView(coverColor: coverColor)
    }

    func ld_removeLoader() {
        self.ld_getCutoutView()?.removeFromSuperview()
        self.ld_getGradient()?.removeAllAnimations()
        self.ld_getGradient()?.removeFromSuperlayer()

        self.subviews.forEach { $0.alpha = 1 }
    }

    func configureAndAddAnimationToGradient(_ gradient: CAGradientLayer) {
        gradient.startPoint = CGPoint(x: -1.0 + CGFloat(gradientWidth), y: 0)
        gradient.endPoint = CGPoint(x: 1.0 + CGFloat(gradientWidth), y: 0)

        gradient.colors = [
            UIColor.backgroundFadedGrey.cgColor,
            UIColor.gradientFirstStop.cgColor,
            UIColor.gradientSecondStop.cgColor,
            UIColor.gradientFirstStop.cgColor,
            UIColor.backgroundFadedGrey.cgColor
        ]

        let startLocations = [
            NSNumber(value: gradient.startPoint.x.doubleValue),
            NSNumber(value: gradient.startPoint.x.doubleValue),
            NSNumber(value: 0 as Double),
            NSNumber(value: gradientWidth),
            NSNumber(value: 1 + gradientWidth)
        ]

        gradient.locations = startLocations
        let gradientAnimation = CABasicAnimation(keyPath: "locations")
        gradientAnimation.fromValue = startLocations
        gradientAnimation.toValue = [
            NSNumber(value: 0 as Double),
            NSNumber(value: 1 as Double),
            NSNumber(value: 1 as Double),
            NSNumber(value: 1 + (gradientWidth - gradientFirstStop)),
            NSNumber(value: 1 + gradientWidth)
        ]

        gradientAnimation.repeatCount = Float.infinity
        gradientAnimation.fillMode = .forwards
        gradientAnimation.isRemovedOnCompletion = false
        gradientAnimation.duration = loaderDuration
        gradient.add(gradientAnimation, forKey: "locations")

        self.ld_setGradient(gradient)
    }

    func addCutoutView(coverColor: UIColor) {
        let cutout = CutoutView()
        cutout.frame = self.bounds
        cutout.coverColor = coverColor
        cutout.backgroundColor = UIColor.clear

        self.addSubview(cutout)
        cutout.setNeedsDisplay()
        cutout.boundInside(self)

        for view in self.subviews {
            guard view != cutout else { continue }
            view.alpha = 0
        }

        self.ld_setCutoutView(cutout)
    }
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

extension UITableView: ListLoadable {
    public func ld_visibleContentViews() -> [UIView] {
        return ((self.visibleCells as NSArray).value(forKey: "contentView") as? [UIView]) ?? []
    }
}

extension UIView {
    @objc public func showLoader() {
        let coverColor: UIColor

        if let backgroundColor = backgroundColor, backgroundColor != .clear {
            // cover image with current backgroundColor if its color is not clearColor
            coverColor = backgroundColor
        } else if let color = superviewColor(view: self) {
            // if not, loop throw parents and find backgroundColor
            coverColor = color
        } else {
            // fall back to default
            coverColor = self.defaultCoverColor
        }

        self.isUserInteractionEnabled = false
        if self is UITableView {
            ListLoader.shared.addLoaderTo(self as! UITableView, coverColor: coverColor)
        } else if self is UICollectionView {
            ListLoader.shared.addLoaderTo(self as! UICollectionView, coverColor: coverColor)
        } else {
            ListLoader.shared.addLoaderToViews([self], coverColor: coverColor)
        }
    }

    @objc public func hideLoader() {
        self.isUserInteractionEnabled = true
        if self is UITableView {
            ListLoader.shared.removeLoaderFrom(self as! UITableView)
        } else if self is UICollectionView {
            ListLoader.shared.removeLoaderFrom(self as! UICollectionView)
        } else {
            ListLoader.shared.removeLoaderFromViews([self])
        }
    }

    private var defaultCoverColor: UIColor {
        var coverColor: UIColor = .white
        if #available(iOS 13.0, *) {
            coverColor = coverColor.onDarkMode(.black)
        }
        return coverColor
    }

    private func superviewColor(view: UIView) -> UIColor? {
        if let superview = view.superview {
            if let color = superview.backgroundColor, color != .clear {
                return color
            }
            return self.superviewColor(view: superview)
        }
        return view.backgroundColor == .clear ? nil : view.backgroundColor
    }
}

extension UICollectionView: ListLoadable {
    public func ld_visibleContentViews() -> [UIView] {
        return ((self.visibleCells as NSArray).value(forKey: "contentView") as? [UIView]) ?? []
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

    static var backgroundFadedGrey: UIColor {
        let lightColor = UIColor(hex: "#F8F8F9")
        if #available(iOS 13.0, *) {
            switch UIApplication.shared.currentWindow?.overrideUserInterfaceStyle {
            case .dark:
                return UIColor(hex: "#232337")
            case .unspecified:
                switch UITraitCollection.current.userInterfaceStyle {
                case .dark:
                    return UIColor(hex: "#232337")
                default:
                    return lightColor
                }
            default:
                return lightColor
            }
        } else {
            return lightColor
        }
    }

    static var gradientFirstStop: UIColor {
        let lightColor = UIColor(hex: "#F8F8F9")
        if #available(iOS 13.0, *) {
            switch UIApplication.shared.currentWindow?.overrideUserInterfaceStyle {
            case .dark:
                return UIColor(hex: "#232337")
            case .unspecified:
                switch UITraitCollection.current.userInterfaceStyle {
                case .dark:
                    return UIColor(hex: "#232337")
                default:
                    return lightColor
                }
            default:
                return lightColor
            }
        } else {
            return lightColor
        }
    }

    static var gradientSecondStop: UIColor {
        let lightColor = UIColor(hex: "#EDEDF0")
        if #available(iOS 13.0, *) {
            switch UIApplication.shared.currentWindow?.overrideUserInterfaceStyle {
            case .dark:
                return UIColor(hex: "#34344E")
            case .unspecified:
                switch UITraitCollection.current.userInterfaceStyle {
                case .dark:
                    return UIColor(hex: "#34344E")
                default:
                    return lightColor
                }
            default:
                return lightColor
            }
        } else {
            return lightColor
        }
    }
}

extension UIView {
    func boundInside(_ superView: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["subview": self]))
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["subview": self]))
    }
}

extension CGFloat {
    var doubleValue: Double {
        return Double(self)
    }
}

extension Notification.Name {
    static var traitCollectionStyleChanged: Notification.Name {
        return Notification.Name("trait_collection_style_changed")
    }
}

extension UIApplication {
    var currentWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first { $0.isKeyWindow }
        }
        return UIApplication.shared.keyWindow
    }
}
