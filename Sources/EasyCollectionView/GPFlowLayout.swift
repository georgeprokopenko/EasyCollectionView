import UIKit
import PinLayout

protocol GPFlowLayoutDelegate: UICollectionViewDelegateFlowLayout {

    func heightForItem(at indexPath: IndexPath, with width: CGFloat, in collectionView: UICollectionView) -> CGFloat
    func spacing(between indexPath: IndexPath, and anotherIndexPath: IndexPath, with width: CGFloat, in collectionView: UICollectionView) -> CGFloat?
    func heightForSupplementaryItem(with kind: String, at indexPath: IndexPath, with width: CGFloat) -> CGFloat?
    func additionalHorizontalInsetsForItem(at indexPath: IndexPath) -> UIEdgeInsets?
    func lineAttributesForItem(at indexPath: IndexPath) -> GPFlowLayout.LineAttributes?
}

// MARK: Default implementations
extension GPFlowLayoutDelegate {

    func spacing(between indexPath: IndexPath, and anotherIndexPath: IndexPath, with width: CGFloat, in collectionView: UICollectionView) -> CGFloat? {
        nil
    }

    func heightForSupplementaryItem(with kind: String, at indexPath: IndexPath, with width: CGFloat) -> CGFloat? {
        nil
    }

    func additionalHorizontalInsetsForItem(at indexPath: IndexPath) -> UIEdgeInsets? {
        nil
    }

    func lineAttributesForItem(at indexPath: IndexPath) -> GPFlowLayout.LineAttributes? {
        nil
    }
}

class GPFlowLayout: UICollectionViewFlowLayout {

    weak var fbFlowLayoutDelegate: GPFlowLayoutDelegate?

    struct LineAttributes: Equatable {
        let numberOfItems: Int
        let spacing: CGFloat

        static let fullWidth = LineAttributes(numberOfItems: 1, spacing: 0)

        init(numberOfItems: Int, spacing: CGFloat) {
            self.numberOfItems = max(numberOfItems, 1)
            self.spacing = spacing
        }
    }

    private var oldBounds: CGRect = .zero
    private var contentHeight: CGFloat = 0
    private var cache = [IndexPath: UICollectionViewLayoutAttributes]()
    private var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()

    override var collectionViewContentSize: CGSize {
        CGSize(width: collectionView?.frame.size.width ?? 0, height: contentHeight)
    }

    private var customRowsCache = [IndexPath: UICollectionViewLayoutAttributes]()

    private var customKindsCache = [String: UICollectionViewLayoutAttributes]()
    class func customKindsCacheKey(for kind: String, indexPath: IndexPath) -> String {
        "\(kind)_\(indexPath.section)_\(indexPath.row)"
    }

    var putContentInCenter: Bool = false {
        didSet {
            invalidateLayout()
        }
    }

    var putContentInCenterAdditionalOffset: CGFloat = 0 {
        didSet {
            guard putContentInCenterAdditionalOffset != oldValue else {
                return
            }

            invalidateLayout()
        }
    }

    var invalidateCustomConfigurationOnScroll: Bool = false

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView, cache.isEmpty else {
            if invalidateCustomConfigurationOnScroll {
                customConfiguration(onScroll: true, cache, &customRowsCache, &customKindsCache, &contentHeight)
            }
            return
        }

        let start = ProcessInfo.processInfo.systemUptime
        defer {
            let end = ProcessInfo.processInfo.systemUptime
            print(String(format: "Did prepare layout [%.2fms]", (end - start) * 1000))
        }

        oldBounds = collectionView.bounds

        var y: CGFloat = 0
        let sectionsCount = collectionView.numberOfSections
        for section in 0 ..< sectionsCount {
            let sectionInset: UIEdgeInsets
            if let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
                let delegateInsets = delegate.collectionView?(collectionView, layout: self, insetForSectionAt: section) {
                sectionInset = delegateInsets
            } else {
                sectionInset = self.sectionInset
            }

            let itemWidth = { (lineAttributes: LineAttributes, customInsets: UIEdgeInsets, roundToPixel: Bool) -> CGFloat in
                let contentWidth = (collectionView.frame.size.width - sectionInset.left - sectionInset.right - customInsets.left - customInsets.right)
                let width = (contentWidth - CGFloat(lineAttributes.numberOfItems - 1) * lineAttributes.spacing) / CGFloat(lineAttributes.numberOfItems)
                return roundToPixel ? Pixel.roundToPixel(width) : width
            }

            let itemX = { (lineAttributes: LineAttributes, customInsets: UIEdgeInsets, itemIndexInLine: Int) -> CGFloat in
                let x: CGFloat
                if itemIndexInLine == lineAttributes.numberOfItems - 1 {
                    x = collectionView.frame.width - sectionInset.right - customInsets.right - itemWidth(lineAttributes, customInsets, false)
                } else {
                    x = sectionInset.left + customInsets.left + (itemWidth(lineAttributes, customInsets, false) + lineAttributes.spacing) * CGFloat(itemIndexInLine)
                }

                return Pixel.roundToPixel(x)
            }

            let rowsCount = collectionView.numberOfItems(inSection: section)
            if rowsCount > 0 {
                y += sectionInset.top
            }

            var currentLineY: CGFloat?
            var currentLineRowsCount = 0
            var currentLineAttributes: LineAttributes?
            var currentLineHorizontalInsets: UIEdgeInsets = .zero

            for row in 0 ..< rowsCount {
                let indexPath = IndexPath(row: row, section: section)
                let lineAttributes = fbFlowLayoutDelegate?.lineAttributesForItem(at: indexPath) ?? .fullWidth
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

                if currentLineAttributes == lineAttributes, currentLineRowsCount < lineAttributes.numberOfItems, let currentLineY = currentLineY {
                    // Append to existing line
                    let x = itemX(lineAttributes, currentLineHorizontalInsets, currentLineRowsCount)
                    let width = itemWidth(lineAttributes, currentLineHorizontalInsets, true)
                    let height = fbFlowLayoutDelegate?.heightForItem(at: indexPath, with: width, in: collectionView) ?? itemSize.height

                    attributes.frame = CGRect(x: x, y: currentLineY, width: width, height: height)
                    cache[indexPath] = attributes

                    currentLineRowsCount += 1
                    y = max(currentLineY + height, y)
                } else {
                    // Start new line

                    let customInsets = fbFlowLayoutDelegate?.additionalHorizontalInsetsForItem(at: indexPath) ?? .zero

                    let x = itemX(lineAttributes, customInsets, 0)
                    let width = itemWidth(lineAttributes, customInsets, true)

                    if row > 0 {
                        let previousIndexPath = IndexPath(row: row - 1, section: section)
                        y += fbFlowLayoutDelegate?.spacing(between: previousIndexPath, and: indexPath, with: width, in: collectionView) ?? minimumLineSpacing
                    }

                    let height = fbFlowLayoutDelegate?.heightForItem(at: indexPath, with: width, in: collectionView) ?? itemSize.height

                    attributes.frame = CGRect(x: x, y: y, width: width, height: height)
                    cache[indexPath] = attributes

                    currentLineAttributes = lineAttributes
                    currentLineRowsCount = 1
                    currentLineHorizontalInsets = customInsets
                    currentLineY = y
                    y += height
                }
            }

            if rowsCount > 0 {
                y += sectionInset.bottom
            }
        }

        contentHeight = y

        let availableContentHeight = collectionView.frame.size.height - (collectionView.contentInset.top + collectionView.contentInset.bottom + collectionView.pin.safeArea.top + collectionView.pin.safeArea.bottom)
        if putContentInCenter && contentHeight <= availableContentHeight {
            let additionY = Pixel.roundToPixel((availableContentHeight - contentHeight) / 2)
            contentHeight += additionY

            cache.forEach { (_, attributes) in
                var frame = attributes.frame
                frame.origin.y += additionY + putContentInCenterAdditionalOffset
                attributes.frame = frame
            }
        }

        customConfiguration(onScroll: false, cache, &customRowsCache, &customKindsCache, &contentHeight)
    }

    func customConfiguration(onScroll: Bool, _ cache: [IndexPath: UICollectionViewLayoutAttributes], _ customRowsCache: inout [IndexPath: UICollectionViewLayoutAttributes], _ customKindsCache: inout [String: UICollectionViewLayoutAttributes], _ contentHeight: inout CGFloat) {
        // Override
    }

    private var skipClearCacheForNextInvalidate = false

    override func invalidateLayout() {
        super.invalidateLayout()

        if skipClearCacheForNextInvalidate {
            skipClearCacheForNextInvalidate = false
        } else {
            cache.removeAll(keepingCapacity: true)
            customRowsCache.removeAll(keepingCapacity: true)
            customKindsCache.removeAll(keepingCapacity: true)
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if newBounds.size != oldBounds.size {
            cache.removeAll(keepingCapacity: true)
            customRowsCache.removeAll(keepingCapacity: true)
            customKindsCache.removeAll(keepingCapacity: true)
            skipClearCacheForNextInvalidate = true
            return true
        }

        if invalidateCustomConfigurationOnScroll && newBounds.origin != oldBounds.origin {
            customRowsCache.removeAll(keepingCapacity: true)
            customKindsCache.removeAll(keepingCapacity: true)
            skipClearCacheForNextInvalidate = true
            return true
        }

        return false
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        customRowsCache[indexPath] ?? cache[indexPath]
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        customKindsCache[GPFlowLayout.customKindsCacheKey(for: elementKind, indexPath: indexPath)]
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        customKindsCache[GPFlowLayout.customKindsCacheKey(for: elementKind, indexPath: indexPath)]
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        visibleLayoutAttributes.removeAll(keepingCapacity: true)

        for (indexPath, attributes) in cache where attributes.frame.intersects(rect) && customRowsCache[indexPath] == nil {
            visibleLayoutAttributes.append(attributes)
        }

        for (_, attributes) in customRowsCache where attributes.frame.intersects(rect) {
            visibleLayoutAttributes.append(attributes)
        }

        for (_, attributes) in customKindsCache where attributes.frame.intersects(rect) {
            visibleLayoutAttributes.append(attributes)
        }

        return visibleLayoutAttributes
    }

    // MARK: - Appearance animations

    @IBInspectable var interceptAnimations: Bool = true
    @IBInspectable var disallowAppearanceAnimation: Bool = true
    var disallowAppearanceAnimationForIndexPaths = [IndexPath]()

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard interceptAnimations else {
            return super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        }

        guard let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath) else {
            return nil
        }

        let newAttributes = attributes.copy() as! UICollectionViewLayoutAttributes

        if disallowAppearanceAnimation || disallowAppearanceAnimationForIndexPaths.contains(itemIndexPath) {
            newAttributes.alpha = 1
        } else {
            newAttributes.alpha = 0
        }

        return newAttributes
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard interceptAnimations else {
            return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        }

        guard let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath) else {
            return nil
        }

        let newAttributes = attributes.copy() as! UICollectionViewLayoutAttributes

        if disallowAppearanceAnimation || disallowAppearanceAnimationForIndexPaths.contains(itemIndexPath) {
            newAttributes.alpha = 1
        } else {
            newAttributes.alpha = 0
        }

        return newAttributes
    }

    override func initialLayoutAttributesForAppearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard interceptAnimations else {
            return super.initialLayoutAttributesForAppearingDecorationElement(ofKind: elementKind, at: decorationIndexPath)
        }

        guard let attributes = super.initialLayoutAttributesForAppearingDecorationElement(ofKind: elementKind, at: decorationIndexPath) else {
            return nil
        }

        attributes.alpha = 1

        return attributes
    }

    override func finalLayoutAttributesForDisappearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard interceptAnimations else {
            return super.finalLayoutAttributesForDisappearingDecorationElement(ofKind: elementKind, at: decorationIndexPath)
        }

        guard let attributes = super.finalLayoutAttributesForDisappearingDecorationElement(ofKind: elementKind, at: decorationIndexPath) else {
            return nil
        }

        attributes.alpha = 1

        return attributes
    }

    override func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard interceptAnimations else {
            return super.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath)
        }

        guard let attributes = super.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath) else {
            return nil
        }

        attributes.alpha = 1

        return attributes
    }

    override func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard interceptAnimations else {
            return super.finalLayoutAttributesForDisappearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath)
        }

        guard let attributes = super.finalLayoutAttributesForDisappearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath) else {
            return nil
        }

        attributes.alpha = 1

        return attributes
    }
}
