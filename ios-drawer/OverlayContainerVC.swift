//
//  OverlayContainerVC.swift
//  ios-drawer
//
//  Created by Keke Arif on 12/10/2018.
//  Copyright © 2018 Keke Arif. All rights reserved.
//

import UIKit

enum OverlayPosition {
    case min, max
}

enum OverlayInFlightPosition {
    case min, max, progressing
}

/// This is the class that will control the animation of the drawer
class OverlayContainerVC: UIViewController {
    
    // Declare the sub viewcontroller and the subview
    private let overlayVc: OverlayVC = OverlayVC()
    private var overlayVcView: UIView!
    
    private var heightConstraint: NSLayoutConstraint!
    
    private var minHeight: CGFloat {
        return view.bounds.height * 0.4
    }
    
    private var maxHeight: CGFloat {
        return view.bounds.height * 0.9
    }
    
    private var defaultDuration: Double = 0.25
    private var maxDuration: Double = 0.4
    private var minimumVelocityConsideration: CGFloat = 100
    
    private var overlayPosition: OverlayPosition = .min
    
    private var overlayInFlightPosition: OverlayInFlightPosition {
        let height: CGFloat = heightConstraint.constant
        if height == maxHeight {
            return .max
        } else if height == minHeight {
            return .min
        } else {
            return .progressing
        }
    }
    
    private var translatedViewTargetHeight: CGFloat {
        switch overlayPosition {
        case .max:
            return maxHeight
        case .min:
            return minHeight
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
    
    private func shouldTranslateView(following scrollView: UIScrollView) -> Bool {
        guard scrollView.isTracking else { return false }
        let offSet: CGFloat = scrollView.contentOffset.y
        switch overlayInFlightPosition {
        case .max:
            return offSet < 0
        case .min:
            return offSet > 0
        case .progressing:
            return true
        }
    }
    
    private func translateView(following scrollView: UIScrollView) {
        scrollView.contentOffset = .zero
        let translation: CGFloat = translatedViewTargetHeight - scrollView.panGestureRecognizer.translation(in: view).y
        heightConstraint.constant = max(minHeight, min(translation, maxHeight))
    }
    
    private func animateTranslationEnd(following scrollView: UIScrollView, velocity: CGPoint) {
        let distance: CGFloat = maxHeight - minHeight
        let progressDistance: CGFloat = heightConstraint.constant - minHeight
        let progress: CGFloat = progressDistance / distance
        let velocityY = -velocity.y * 100
        if abs(velocityY) > minimumVelocityConsideration && progress != 0 && progress != 1 {
            let rest = abs(distance - progressDistance)
            let position: OverlayPosition
            let duration = TimeInterval(rest / abs(velocityY))
            if velocityY > 0 {
                position = .min
            } else {
                position = .max
            }
            moveOverlay(to: position, duration: duration, velocity: velocity)
        } else {
            if progress < 0.5 {
                moveOverlay(to: .min)
            } else {
                moveOverlay(to: .max)
            }
        }
    }
    
    // MARK: - Animation
    
    private func moveOverlay(to position: OverlayPosition, duration: TimeInterval, velocity: CGPoint) {
        overlayPosition = position
        heightConstraint.constant = translatedViewTargetHeight
        UIView.animate(
            withDuration: min(duration, maxDuration),
            delay: 0,
            usingSpringWithDamping: velocity.y == 0 ? 1 : 0.6,
            initialSpringVelocity: abs(velocity.y),
            options: [.allowUserInteraction],
            animations: {
                self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func moveOverlay(to position: OverlayPosition) {
        moveOverlay(to: position, duration: defaultDuration, velocity: .zero)
    }

}

// MARK: - OverlayVCDelegate Methods

extension OverlayContainerVC: OverlayVCDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard shouldTranslateView(following: scrollView) else { return }
        translateView(following: scrollView)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        switch overlayInFlightPosition {
        case .max:
            break
        case .min, .progressing:
            targetContentOffset.pointee = .zero
        }
        animateTranslationEnd(following: scrollView, velocity: velocity)
    }
    
}
