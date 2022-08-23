//
//  CutoutView.swift
//  ListPlaceholder
//
//  Created by Ruben Nahatakyan on 23.08.22.
//

import UIKit

@objc class CutoutView: UIView {
    var coverColor: UIColor = .white

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(self.coverColor.cgColor)
        context?.fill(self.bounds)

        for view in self.superview?.subviews ?? [] {
            guard view != self else { continue }
            if #available(iOS 9.0, *), let stackView = view as? UIStackView {
                recursivelyDrawCutOutInStackView(stackView, fromParentView: view.superview!, context: context)
            } else {
                self.drawPath(context: context, view: view)
            }
        }
    }

    @available(iOS 9.0, *)
    private func recursivelyDrawCutOutInStackView(_ stackView: UIStackView, fromParentView parentView: UIView, context: CGContext?) {
        stackView.arrangedSubviews.forEach { arrangedSubview in
            if let arrangedSubviewStackView = arrangedSubview as? UIStackView {
                recursivelyDrawCutOutInStackView(arrangedSubviewStackView, fromParentView: parentView, context: context)
                return
            }
            let frame = stackView.convert(arrangedSubview.frame, to: parentView)
            drawPath(context: context, view: arrangedSubview, fixedFrame: frame)
        }
    }

    private func drawPath(context: CGContext?, view: UIView, fixedFrame: CGRect? = nil) {
        let frame = fixedFrame ?? view.frame
        context?.setBlendMode(.clear)
        let rect = frame
        let clipPath: CGPath = UIBezierPath(roundedRect: rect, cornerRadius: view.layer.cornerRadius).cgPath
        context?.addPath(clipPath)
        context?.setFillColor(UIColor.clear.cgColor)
        context?.closePath()
        context?.fillPath()
    }

    override func layoutSubviews() {
        self.setNeedsDisplay()
        self.superview?.ld_getGradient()?.frame = (self.superview?.bounds)!
    }
}
