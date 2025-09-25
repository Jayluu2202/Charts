//
//  Utils.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

//
//  Utils.swift
//  Charts
//

import Foundation
import CoreGraphics
import UIKit
import ObjectiveC

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

extension FloatingPoint {
    var DEG2RAD: Self { self * .pi / 180 }
    var RAD2DEG: Self { self * 180 / .pi }

    var normalizedAngle: Self {
        let angle = truncatingRemainder(dividingBy: 360)
        return angle < 0 ? angle + 360 : angle
    }
}

extension CGSize {
    func rotatedBy(degrees: CGFloat) -> CGSize {
        rotatedBy(radians: degrees.DEG2RAD)
    }

    func rotatedBy(radians: CGFloat) -> CGSize {
        CGSize(
            width: abs(width * cos(radians)) + abs(height * sin(radians)),
            height: abs(width * sin(radians)) + abs(height * cos(radians))
        )
    }
}

extension Double {
    func roundedToNextSignificant() -> Double {
        guard !isInfinite, !isNaN, self != 0 else { return self }
        let d = ceil(log10(self < 0 ? -self : self))
        let pw = 1 - Int(d)
        let magnitude = pow(10.0, Double(pw))
        let shifted = (self * magnitude).rounded()
        return shifted / magnitude
    }

    var decimalPlaces: Int {
        guard !isNaN, !isInfinite, self != 0.0 else { return 0 }
        let i = roundedToNextSignificant()
        guard !i.isInfinite, !i.isNaN else { return 0 }
        return Int(ceil(-log10(i))) + 2
    }
}

extension CGPoint {
    func moving(distance: CGFloat, atAngle angle: CGFloat) -> CGPoint {
        CGPoint(x: x + distance * cos(angle.DEG2RAD),
                y: y + distance * sin(angle.DEG2RAD))
    }
}

extension CGContext {

    public func drawImage(_ image: UIImage, atCenter center: CGPoint, size: CGSize) {
        var drawOffset = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
        UIGraphicsPushContext(self)

        if image.size != size {
            let key = "resized_\(size.width)_\(size.height)"
            var scaledImage = objc_getAssociatedObject(image, key) as? UIImage

            if scaledImage == nil {
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                image.draw(in: CGRect(origin: .zero, size: size))
                scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                objc_setAssociatedObject(image, key, scaledImage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }

            scaledImage?.draw(in: CGRect(origin: drawOffset, size: size))
        } else {
            image.draw(in: CGRect(origin: drawOffset, size: size))
        }

        UIGraphicsPopContext()
    }

    public func drawText(
        _ text: String,
        at point: CGPoint,
        align: NSTextAlignment,
        anchor: CGPoint = CGPoint(x: 0.5, y: 0.5),
        angleRadians: CGFloat = 0.0,
        attributes: [NSAttributedString.Key: Any]?
    ) {
        let drawPoint = getDrawPoint(text: text, point: point, align: align, attributes: attributes)
        if angleRadians == 0.0 {
            UIGraphicsPushContext(self)
            (text as NSString).draw(at: drawPoint, withAttributes: attributes)
            UIGraphicsPopContext()
        } else {
            drawText(text, at: drawPoint, anchor: anchor, angleRadians: angleRadians, attributes: attributes)
        }
    }

    public func drawText(
        _ text: String,
        at point: CGPoint,
        anchor: CGPoint = CGPoint(x: 0.5, y: 0.5),
        angleRadians: CGFloat,
        attributes: [NSAttributedString.Key: Any]?
    ) {
        var drawOffset = CGPoint.zero
        UIGraphicsPushContext(self)

        if angleRadians != 0.0 {
            let size = text.size(withAttributes: attributes)
            drawOffset.x = -size.width * 0.5
            drawOffset.y = -size.height * 0.5
            var translate = point

            if anchor != CGPoint(x: 0.5, y: 0.5) {
                let rotatedSize = size.rotatedBy(radians: angleRadians)
                translate.x -= rotatedSize.width * (anchor.x - 0.5)
                translate.y -= rotatedSize.height * (anchor.y - 0.5)
            }

            saveGState()
            translateBy(x: translate.x, y: translate.y)
            rotate(by: angleRadians)
            (text as NSString).draw(at: drawOffset, withAttributes: attributes)
            restoreGState()
        } else {
            let size = text.size(withAttributes: attributes)
            drawOffset.x = -size.width * anchor.x + point.x
            drawOffset.y = -size.height * anchor.y + point.y
            (text as NSString).draw(at: drawOffset, withAttributes: attributes)
        }

        UIGraphicsPopContext()
    }

    private func getDrawPoint(
        text: String,
        point: CGPoint,
        align: NSTextAlignment,
        attributes: [NSAttributedString.Key: Any]?
    ) -> CGPoint {
        var point = point
        let textWidth = text.size(withAttributes: attributes).width
        switch align {
        case .center:
            point.x -= textWidth / 2
        case .right:
            point.x -= textWidth
        default:
            break
        }
        return point
    }

    func drawMultilineText(
        _ text: String,
        at point: CGPoint,
        constrainedTo size: CGSize,
        anchor: CGPoint,
        knownTextSize: CGSize,
        angleRadians: CGFloat,
        attributes: [NSAttributedString.Key: Any]?
    ) {
        var rect = CGRect(origin: .zero, size: knownTextSize)
        UIGraphicsPushContext(self)

        if angleRadians != 0.0 {
            rect.origin.x = -knownTextSize.width * 0.5
            rect.origin.y = -knownTextSize.height * 0.5
            var translate = point

            if anchor != CGPoint(x: 0.5, y: 0.5) {
                let rotatedSize = knownTextSize.rotatedBy(radians: angleRadians)
                translate.x -= rotatedSize.width * (anchor.x - 0.5)
                translate.y -= rotatedSize.height * (anchor.y - 0.5)
            }

            saveGState()
            translateBy(x: translate.x, y: translate.y)
            rotate(by: angleRadians)
            (text as NSString).draw(with: rect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            restoreGState()
        } else {
            rect.origin.x = -knownTextSize.width * anchor.x + point.x
            rect.origin.y = -knownTextSize.height * anchor.y + point.y
            (text as NSString).draw(with: rect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        }

        UIGraphicsPopContext()
    }

    func drawMultilineText(
        _ text: String,
        at point: CGPoint,
        constrainedTo size: CGSize,
        anchor: CGPoint,
        angleRadians: CGFloat,
        attributes: [NSAttributedString.Key: Any]?
    ) {
        let rect = text.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        drawMultilineText(text, at: point, constrainedTo: size, anchor: anchor, knownTextSize: rect.size, angleRadians: angleRadians, attributes: attributes)
    }
}
