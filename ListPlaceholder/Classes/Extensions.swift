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

@objc extension UIView {
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

@objc extension UITableView: ListLoadable {
    public func ld_visibleContentViews() -> [UIView] {
        return ((self.visibleCells as NSArray).value(forKey: "contentView") as? [UIView]) ?? []
    }
}

@objc extension UIView {
    public func showLoader() {
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

    public func hideLoader() {
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

@objc extension UICollectionView: ListLoadable {
    public func ld_visibleContentViews() -> [UIView] {
        return ((self.visibleCells as NSArray).value(forKey: "contentView") as? [UIView]) ?? []
    }
}

@objc extension UIColor {
    static var backgroundFadedGrey: UIColor {
        let lightColor = UIColor(red: 246.0/255.0, green: 247.0/255.0, blue: 248.0/255.0, alpha: 1)
        if #available(iOS 13.0, *) {
            switch UITraitCollection.current.userInterfaceStyle {
            case .dark:
                return UIColor(red: 9/255.0, green: 8/255.0, blue: 7/255.0, alpha: 1)
            default:
                return lightColor
            }
        } else {
            return lightColor
        }
    }

    static var gradientFirstStop: UIColor {
        let lightColor = UIColor(red: 238.0/255.0, green: 238.0/255.0, blue: 238.0/255.0, alpha: 1.0)
        if #available(iOS 13.0, *) {
            switch UITraitCollection.current.userInterfaceStyle {
            case .dark:
                return UIColor(red: 17/255.0, green: 17/255.0, blue: 17/255.0, alpha: 1.0)
            default:
                return lightColor
            }
        } else {
            return lightColor
        }
    }

    static var gradientSecondStop: UIColor {
        let lightColor = UIColor(red: 221.0/255.0, green: 221.0/255.0, blue: 221.0/255.0, alpha: 1.0)
        if #available(iOS 13.0, *) {
            switch UITraitCollection.current.userInterfaceStyle {
            case .dark:
                return UIColor(red: 34/255.0, green: 34/255.0, blue: 34/255.0, alpha: 1.0)
            default:
                return lightColor
            }
        } else {
            return lightColor
        }
    }
}

@objc extension UIView {
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
