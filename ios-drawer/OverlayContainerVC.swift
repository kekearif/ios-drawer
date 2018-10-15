//
//  OverlayContainerVC.swift
//  ios-drawer
//
//  Created by Keke Arif on 12/10/2018.
//  Copyright © 2018 Keke Arif. All rights reserved.
//

import UIKit

enum OverlayPosition {
    case close, min, max
}

enum OverlayInFlightPosition {
    case min, max, maxStretch, belowMin, minCompress
}

/// This is the class that will control the animation of the drawer
class OverlayContainerVC: UIViewController {
    
    // Declare the sub viewcontroller and the subview
    private let overlayVc: OverlayVC = OverlayVC()
    private var overlayVcView: UIView!
    
    private var heightConstraint: NSLayoutConstraint!
    private var prevTranslation: CGFloat = 0
    
    private var minHeight: CGFloat {
        return view.bounds.height * 0.5
    }
    
    private var maxHeight: CGFloat {
        return view.bounds.height * 0.8
    }
    
    private var maxStretch: CGFloat {
        return view.bounds.height * 0.93
    }
    
    private var minCompress: CGFloat {
        return view.bounds.height * 0.2
    }
    
    private var decelarationRate: CGFloat {
        return UIScrollView.DecelerationRate.normal.rawValue
    }
    
    private var duration: Double = 0.3
    
    private var overlayInFlightPosition: OverlayInFlightPosition {
        let height: CGFloat = heightConstraint.constant
        if height >= maxStretch {
            return .maxStretch
        } else if height >= maxHeight {
            return .max
        } else if height >= minHeight {
            return .min
        } else if height >= minCompress{
            return .belowMin
        } else {
            return .minCompress
        }
    }
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        overlayVc.delegate = self
        addChild(overlayVc)
        overlayVc.didMove(toParent: self)
        
        overlayVcView = overlayVc.view
        overlayVcView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayVcView)
        heightConstraint = NSLayoutConstraint(item: overlayVcView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100)
        overlayVcView.addConstraint(heightConstraint)
        overlayVcView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        overlayVcView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        overlayVcView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moveOverlay(to: .min)
    }
    
    override func loadView() {
        // New UIView so the background with be transparent
        view = UIView()
    }
    
    // MARK: - Scroll Control
    
    // Decide if to scroll or not
    private func shouldTranslateView(following scrollView: UIScrollView) -> Bool {
        let offSet: CGFloat = scrollView.contentOffset.y
        switch overlayInFlightPosition {
        case .maxStretch:
            return offSet < 0
        default:
            return true
        }
    }
    
    // Dragging
    private func translateView(following scrollView: UIScrollView) {
        scrollView.contentOffset = .zero
        let translation: CGFloat = heightConstraint.constant - scrollView.panGestureRecognizer.translation(in: view).y + prevTranslation
        heightConstraint.constant = translation
        prevTranslation = scrollView.panGestureRecognizer.translation(in: view).y
    }
    
    // Called when the dragging ends
    private func animateTranslationEnd(following scrollView: UIScrollView, velocity: CGPoint) {
        // Velocity is +ve when flicked up, it's pts per millisecond
        print("the velocity is \(velocity.y * 1000) per second!")
        // This is pts per second
        
        
        print("the distance is \(project(velocity: velocity, decelarationRate: decelarationRate))")
        heightConstraint.constant += project(velocity: velocity, decelarationRate: decelarationRate)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 100, initialSpringVelocity: 30, options: [.curveEaseOut, .allowUserInteraction], animations: {() in
            self.view.layoutIfNeeded()
        }, completion: nil)
        
    }
    
    private func project(velocity: CGPoint, decelarationRate: CGFloat) -> CGFloat {
        return ((velocity.y * velocity.y) / 2 * decelarationRate) * 10
    }
    
    // MARK: - Animation
    
    private func moveOverlay(to position: OverlayPosition) {
        switch position {
        case .close:
            heightConstraint.constant = 0
        case .min:
            heightConstraint.constant = minHeight
        case .max:
            heightConstraint.constant = maxHeight
        }
        UIView.animate(withDuration: duration, animations: {() in
            self.view.layoutIfNeeded()
        })
    }

}

// MARK: - OverlayVCDelegate Methods

extension OverlayContainerVC: OverlayVCDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard shouldTranslateView(following: scrollView) else { return }
        translateView(following: scrollView)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        prevTranslation = 0
        animateTranslationEnd(following: scrollView, velocity: velocity)
    }
    
}
