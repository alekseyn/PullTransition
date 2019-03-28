//
//  VectorMath.swift
//  PullTransition
//
//  Adapted by Aleksey Novicov on 12/20/17 from examples by Apple Inc.
//

import QuartzCore

public extension CGPoint {
	var vector: CGVector {
		return CGVector(dx: x, dy: y)
	}
}

public extension CGVector {
	var magnitude: CGFloat {
		return sqrt(dx*dx + dy*dy)
	}
	
	var point: CGPoint {
		return CGPoint(x: dx, y: dy)
	}
	
	func apply(transform t: CGAffineTransform) -> CGVector {
		return point.applying(t).vector
	}
	
	func scaled(by scale: CGFloat) -> CGVector {
		return CGVector(dx: self.dx * scale, dy: self.dy * scale)
	}
}

