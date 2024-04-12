import UIKit
import Foundation

public struct Pixel {

    public static var size: CGFloat = {
        1.0 / UIScreen.main.scale
    }()

    public static func roundToPixel(_ value: CGFloat) -> CGFloat {
        let screenScale = UIScreen.main.scale
        return round(value * screenScale) / screenScale
    }

    public static func floorToPixel(_ value: CGFloat) -> CGFloat {
        let screenScale = UIScreen.main.scale
        return floor(value * screenScale) / screenScale
    }

    public static func ceilToPixel(_ value: CGFloat) -> CGFloat {
        let screenScale = UIScreen.main.scale
        return ceil(value * screenScale) / screenScale
    }
}
