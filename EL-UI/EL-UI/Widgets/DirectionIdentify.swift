//
//  DirectionIdentify.swift
//  EL-UI
//
//  Created by WJR on 4/9/24.
//

import SwiftUI
import AVFoundation

enum SwipeDirection {
  case left, right, up, down, none
}

typealias SwipeAction = (SwipeDirection) -> Void

struct SwipeGestureModifier: ViewModifier {
  let swipeAction: SwipeAction
  @State private var startPoint: CGPoint?
  
  func body(content: Content) -> some View {
    content.gesture(
      DragGesture()
        .onChanged { ges in
          if startPoint == nil {
            startPoint = ges.location
          }
        }
        .onEnded { ges in
          let direction = self.determineSwipeDirection(startPoint: startPoint, endPoint: ges.location)
          swipeAction(direction)
          startPoint = nil
        }
    )
  }
  

  private func determineSwipeDirection(startPoint: CGPoint?, endPoint: CGPoint) -> SwipeDirection {
    if let startPoint = startPoint {
      let dx = abs(endPoint.x - startPoint.x)
      let dy = abs(endPoint.y - startPoint.y)
      
      if startPoint.y < endPoint.y && dy > dx {
        return .down
      } else if startPoint.y > endPoint.y && dy > dx {
        return .up
      } else if startPoint.x < endPoint.x && dx > dy {
        return .right
      } else if startPoint.x > endPoint.x && dx > dy {
        return .left
      } else {
        return .none
      }
    }
    return .none
  }
}

extension View {
  func onSwipeGesture(swipeAction: @escaping SwipeAction) -> some View {
    self.modifier(SwipeGestureModifier(swipeAction: swipeAction))
  }
}
