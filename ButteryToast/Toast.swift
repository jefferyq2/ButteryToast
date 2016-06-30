//
//  Toast.swift
//  ButteryToast
//
//  Created by creisterer on 11/3/15.
//  Copyright © 2015 Starry. All rights reserved.
//

import Foundation
import UIKit

/**
 A toast contains a view for presentation by a Toaster.
 Toasts are unique - even two Toasts containing the same view are still different Toasts.
 This allows for managing toasts in a queue and determining if they have been presented yet.
 */
public class Toast: Equatable {

  private let view: UIView
  private let dismissAfter: NSTimeInterval?

  private let height: CGFloat?

  /**
   Initializes the `Toast` instance with the specified view.
   - parameter dismissAfter: If set, the time interval after which a Toast will auto-dismiss without user interaction. If unset, a Toast will persist until dismissed.
   - parameter height: If set, the height of the toast, enforced by AutoLayout. If unset, the height will be determined soley from the intrinsic content size of the view passed to the Toast.
  */
  public init(view: UIView, dismissAfter: NSTimeInterval? = nil, height: CGFloat?=nil) {
    self.view = view
    self.dismissAfter = dismissAfter
    self.height = height
  }

  private var messageView: ToastView?
  weak var delegate: ToastDelegate?  // messenger that presented message

  internal func displayInViewController(viewController: UIViewController) {

    let alertView = ToastView(contentView: view)
    alertView.translatesAutoresizingMaskIntoConstraints = false

    var constraints: [NSLayoutConstraint] = []
    let parentView: UIView

    // place the alert in navigation bar if possible
    if let navigationController = viewController.navigationController {
      parentView = navigationController.view
      navigationController.view.insertSubview(alertView, belowSubview: navigationController.navigationBar)

      constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["alertView": alertView])

      if navigationController.navigationBar.hidden {
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:[topGuide]-0-[alertView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["topGuide": navigationController.topLayoutGuide, "alertView": alertView])
      } else {
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:[navBar]-0-[alertView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["navBar": navigationController.navigationBar, "alertView": alertView])
      }
    } else {
      // no navigation bar, just place on view controller at top
      parentView = viewController.view
      viewController.view.addSubview(alertView)

      constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["alertView": alertView])

      constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:[topGuide]-0-[alertView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["topGuide": viewController.topLayoutGuide, "alertView": alertView])
    }
    if let height = height {
      constraints.append(NSLayoutConstraint(item: alertView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: height))
    }

    parentView.addConstraints(constraints)

    alertView.setNeedsLayout()
    alertView.layoutIfNeeded()

    alertView.alpha = 0.0
    alertView.transform = CGAffineTransformMakeTranslation(0.0, -alertView.bounds.height)
    UIView.animateWithDuration(0.25) {
      alertView.alpha = 1.0
      alertView.transform = CGAffineTransformIdentity
    }

    let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    alertView.addGestureRecognizer(tapGR)

    // setup delayed dismissal
    if let dismissAfter = dismissAfter {
      let delay = Int64(Double(dismissAfter) * Double(NSEC_PER_SEC))
      let after = dispatch_time(DISPATCH_TIME_NOW, delay)
      dispatch_after(after, dispatch_get_main_queue()) { [weak self] in
        self?.dismiss()
      }
    }

    messageView = alertView

  }

  @objc func handleTap(tapGesture: UITapGestureRecognizer) {
    dismiss()
  }

  func dismiss() {
    if let messageView = messageView {
      UIView.animateWithDuration(0.25, animations: {
        messageView.alpha = 0.0
        messageView.transform = CGAffineTransformMakeTranslation(0.0, -messageView.bounds.height)
        }, completion: { success in
          messageView.removeFromSuperview()
          self.delegate?.toastDismissed(self)
      })
    } else {
      delegate?.toastDismissed(self)
    }
  }
}

public func ==(lhs: Toast, rhs: Toast) -> Bool {
  return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}


protocol ToastDelegate: class {
  
  func toastDismissed(toast: Toast)
  
}