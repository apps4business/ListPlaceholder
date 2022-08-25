//
// Copyright (c) 2017 malkouz
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit

@objc public protocol ListLoadable {
    func ld_visibleContentViews() -> [UIView]
}

@objc open class ListLoader: NSObject {
    public static let shared = ListLoader()

    private var views: [LoaderView] = []

    override private init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.traitCollectionStyleChanged(_:)), name: .traitCollectionStyleChanged, object: nil)
    }

    func addLoaderToViews(_ views: [UIView], coverColor: UIColor) {
        CATransaction.begin()
        views.forEach {
            self.views.append(LoaderView(views: [$0], color: coverColor))
            $0.ld_addLoader(coverColor: coverColor)
        }
        CATransaction.commit()
    }

    func removeLoaderFromViews(_ views: [UIView]) {
        for view in views {
            self.views.removeAll(where: { $0.views.allObjects.contains(view) })
        }
        CATransaction.begin()
        views.forEach { $0.ld_removeLoader() }
        CATransaction.commit()
    }

    public func addLoaderTo(_ list: ListLoadable, coverColor: UIColor) {
        self.views.append(LoaderView(views: list.ld_visibleContentViews(), color: coverColor))
        self.addLoaderToViews(list.ld_visibleContentViews(), coverColor: coverColor)
    }

    public func removeLoaderFrom(_ list: ListLoadable) {
        self.removeLoaderFromViews(list.ld_visibleContentViews())
    }

    @objc private func traitCollectionStyleChanged(_ sender: Notification) {
        self.views = self.views.filter { !$0.views.allObjects.isEmpty }
        self.views.forEach {
            let objects = $0.views.allObjects
            removeLoaderFromViews(objects)
            addLoaderToViews(objects, coverColor: $0.color)
        }
    }
}

private class LoaderView: NSObject {
    var views = NSHashTable<UIView>.weakObjects()
    let color: UIColor

    init(views: [UIView], color: UIColor) {
        self.color = color
        super.init()
        views.forEach { self.views.add($0) }
    }
}
