import UIKit

class CommonRowCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)

        _loadLayout()
    }

    required init?(coder aDecoder: NSCoder) {
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

    func loadLayout() {
        fatalError("Override me")
    }
}
