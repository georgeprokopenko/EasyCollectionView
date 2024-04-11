import UIKit
import Foundation

struct Pixel {

    static var size: CGFloat = {
        1.0 / UIScreen.main.scale
    }()

    static func roundToPixel(_ value: CGFloat) -> CGFloat {
        let screenScale = UIScreen.main.scale
        return round(value * screenScale) / screenScale
    }

    static func floorToPixel(_ value: CGFloat) -> CGFloat {
        let screenScale = UIScreen.main.scale
        return floor(value * screenScale) / screenScale
    }

    static func ceilToPixel(_ value: CGFloat) -> CGFloat {
        let screenScale = UIScreen.main.scale
        return ceil(value * screenScale) / screenScale
    }
}
