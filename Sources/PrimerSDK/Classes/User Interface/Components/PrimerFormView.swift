//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import UIKit

class PrimerFormView: PrimerView {
    
    //MARK: - Properties
    
    private(set) internal var verticalStackView = UIStackView()
    private(set) internal var formViews: [[UIView?]]?
    private(set) internal var verticalStackSpacing: CGFloat = PrimerDimensions.StackViewSpacing.default
    private(set) internal var horizontalStackSpacing: CGFloat = PrimerDimensions.StackViewSpacing.default
    
    //MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
}

extension PrimerFormView {
    
    convenience init(frame: CGRect = .zero,
                     formViews:  [[UIView?]]?,
                     verticalStackSpacing: CGFloat = PrimerDimensions.StackViewSpacing.default,
                     horizontalStackSpacing: CGFloat = PrimerDimensions.StackViewSpacing.default) {
        self.init(frame: frame)
        self.formViews = formViews
        self.verticalStackSpacing = verticalStackSpacing
        self.horizontalStackSpacing = horizontalStackSpacing
        self.initialize()
    }

}
extension PrimerFormView {
    
    private func initialize() {
        addSubview(verticalStackView)
        setupVerticalStackView()
        evaluateAddViewsToStackView()
    }
    
    private func makeHorizontalStackViewWithViews(_ views: [UIView]) -> UIStackView {
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .fill
        horizontalStackView.distribution = .fillEqually
        horizontalStackView.spacing = horizontalStackSpacing
        views.forEach { horizontalStackView.addArrangedSubview($0) }
        return horizontalStackView
    }
    
    private func setupVerticalStackView() {
        verticalStackView.axis = .vertical
        verticalStackView.spacing = verticalStackSpacing
        verticalStackView.alignment = .fill

        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        verticalStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        verticalStackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    private func evaluateAddViewsToStackView() {
        
        // Loop into all views
        formViews?.forEach {
            
            // 1 element = 1 view added as part of the vertical stack
            if $0.count == 1, let view = $0.first, let view = view {
                
                verticalStackView.addArrangedSubview(view)
            
            // 2+ elements = views added as part of a new horizontal stackview
            // the horizonal stack view is added to the main vertical one
            } else if $0.count > 1 {
                
                verticalStackView.addArrangedSubview(makeHorizontalStackViewWithViews($0.compactMap { $0 }))
            }
        }
    }
}

#endif
