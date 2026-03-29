import AppKit

extension NSScreen {
    var hasNotch: Bool {
        safeAreaInsets.top != 0
    }

    var notchHeight: CGFloat {
        safeAreaInsets.top
    }

    var notchWidth: CGFloat {
        let leftWidth = auxiliaryTopLeftArea?.width ?? 0
        let rightWidth = auxiliaryTopRightArea?.width ?? 0
        return frame.width - leftWidth - rightWidth
    }
}
