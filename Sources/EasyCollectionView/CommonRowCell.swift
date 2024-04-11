import UIKit

public class CommonRowCell: UICollectionViewCell {

    public override init(frame: CGRect) {
        super.init(frame: frame)

        _loadLayout()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        _loadLayout()
    }

    private var didLoadLayout: Bool = false

    private func _loadLayout() {
        guard !didLoadLayout else {
            return
        }

        contentView.isUserInteractionEnabled = false

        loadLayout()
        setNeedsLayout()

        didLoadLayout = true
    }

    public func loadLayout() {
        fatalError("Override me")
    }
}
