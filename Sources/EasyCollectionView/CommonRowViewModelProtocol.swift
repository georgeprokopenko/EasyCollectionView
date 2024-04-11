import UIKit

@objc
public protocol CommonRowViewModelProtocol: AnyObject {

    var rowId: String { get }
    @objc optional var nibName: String { get }
    @objc optional var cellClass: AnyClass { get }

    func configure(_ cell: Any)
    @objc optional func rebind(_ cell: Any)
    @objc optional func height(with width: CGFloat) -> CGFloat
    @objc optional func setHeightDidUpdateHandler(_ handler: @escaping () -> Void)

    @objc optional func willDisplay(cell: Any)
    @objc optional func didHide(cell: Any)
}
