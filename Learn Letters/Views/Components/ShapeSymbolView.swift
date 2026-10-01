//
//  ShapeSymbolView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/09/2026.
//

import SwiftUI

struct ShapeSymbolView: View {
    let kind: ShapeKind
    let color: Color

    var body: some View {
        Group {
            switch kind {
            case .circle:
                Circle().fill(color)
            case .oval:
                Ellipse().fill(color)
            case .triangle:
                TriangleShape().fill(color)
            case .square:
                Rectangle().fill(color)
            case .rectangle:
                Rectangle().fill(color)
            case .diamond:
                DiamondShape().fill(color)
            case .arrow:
                ArrowShape().fill(color)
            case .heart:
                HeartShape().fill(color)
            case .crescent:
                CrescentShape().fill(color)
            case .star:
                StarShape(points: 5, innerRadiusRatio: 0.46).fill(color)
            case .cloud:
                CloudShape().fill(color)
            case .pentagon:
                RegularPolygonShape(sides: 5).fill(color)
            case .hexagon:
                RegularPolygonShape(sides: 6).fill(color)
            case .octagon:
                RegularPolygonShape(sides: 8).fill(color)
            case .rhombus:
                RhombusShape().fill(color)
            }
        }
    }
}

private struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * side, y: origin.y + y * side)
        }

        return Path { path in
            path.move(to: point(0.50, 0.29)) // notch between two rounded lobes
            path.addCurve(to: point(0.28, 0.12), control1: point(0.43, 0.16), control2: point(0.36, 0.12))
            path.addCurve(to: point(0.07, 0.39), control1: point(0.14, 0.12), control2: point(0.07, 0.23))
            path.addCurve(to: point(0.50, 0.94), control1: point(0.07, 0.63), control2: point(0.34, 0.83))
            path.addCurve(to: point(0.93, 0.39), control1: point(0.66, 0.83), control2: point(0.93, 0.63))
            path.addCurve(to: point(0.72, 0.12), control1: point(0.93, 0.23), control2: point(0.86, 0.12))
            path.addCurve(to: point(0.50, 0.29), control1: point(0.64, 0.12), control2: point(0.57, 0.16))
            path.closeSubpath()
        }
    }
}

private struct CrescentShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * side, y: origin.y + y * side)
        }

        return Path { path in
            // Both edges meet at the tips; the right-hand curve scoops out the moon.
            path.move(to: point(0.79, 0.16))
            path.addCurve(to: point(0.11, 0.50), control1: point(0.49, 0.00), control2: point(0.11, 0.16))
            path.addCurve(to: point(0.79, 0.84), control1: point(0.11, 0.84), control2: point(0.49, 1.00))
            path.addCurve(to: point(0.79, 0.16), control1: point(0.39, 0.77), control2: point(0.39, 0.23))
            path.closeSubpath()
        }
    }
}

private struct StarShape: Shape {
    let points: Int
    let innerRadiusRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        guard points >= 2 else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRadiusRatio
        let angleIncrement = Double.pi / Double(points)
        let startAngle = -Double.pi / 2

        return Path { path in
            for index in 0..<(points * 2) {
                let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
                let angle = startAngle + (Double(index) * angleIncrement)
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                )

                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }
}

private struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * side, y: origin.y + y * side)
        }

        let left = CGPoint(x: 0.22, y: 0.60)
        let middle = CGPoint(x: 0.50, y: 0.48)
        let right = CGPoint(x: 0.78, y: 0.60)
        let smallRadius: CGFloat = 0.16
        let largeRadius: CGFloat = 0.25

        // Upper intersection of the left and middle circles; the right is its mirror.
        let dx = middle.x - left.x
        let dy = middle.y - left.y
        let distance = hypot(dx, dy)
        let along = (smallRadius * smallRadius - largeRadius * largeRadius + distance * distance) / (2 * distance)
        let above = sqrt(smallRadius * smallRadius - along * along)
        let join = CGPoint(
            x: left.x + along * dx / distance + above * dy / distance,
            y: left.y + along * dy / distance - above * dx / distance
        )
        let rightJoin = CGPoint(x: 1 - join.x, y: join.y)

        func angle(from center: CGPoint, to location: CGPoint) -> Double {
            let degrees = atan2(Double(location.y - center.y), Double(location.x - center.x)) * 180 / .pi
            return degrees < 0 ? degrees + 360 : degrees
        }

        return Path { path in
            path.move(to: point(left.x, left.y + smallRadius))
            path.addArc(center: point(left.x, left.y), radius: smallRadius * side,
                        startAngle: .degrees(90), endAngle: .degrees(angle(from: left, to: join)), clockwise: false)
            path.addArc(center: point(middle.x, middle.y), radius: largeRadius * side,
                        startAngle: .degrees(angle(from: middle, to: join)),
                        endAngle: .degrees(angle(from: middle, to: rightJoin)), clockwise: false)
            path.addArc(center: point(right.x, right.y), radius: smallRadius * side,
                        startAngle: .degrees(angle(from: right, to: rightJoin)), endAngle: .degrees(450), clockwise: false)
            path.addLine(to: point(left.x, left.y + smallRadius))
            path.closeSubpath()
        }
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height * 2 / sqrt(3))
        let height = side * sqrt(3) / 2
        let x = rect.midX - side / 2
        let y = rect.midY - height / 2

        return Path { path in
            path.move(to: CGPoint(x: rect.midX, y: y))
            path.addLine(to: CGPoint(x: x + side, y: y + height))
            path.addLine(to: CGPoint(x: x, y: y + height))
            path.closeSubpath()
        }
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
        }
    }
}

private struct RhombusShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.16

        return Path { path in
            path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

private struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let shaftHeight = rect.height * 0.34
        let shaftTop = rect.midY - (shaftHeight / 2)
        let shaftBottom = rect.midY + (shaftHeight / 2)
        let shaftEnd = rect.width * 0.52

        return Path { path in
            path.move(to: CGPoint(x: rect.minX, y: shaftTop))
            path.addLine(to: CGPoint(x: shaftEnd, y: shaftTop))
            path.addLine(to: CGPoint(x: shaftEnd, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: shaftEnd, y: rect.maxY))
            path.addLine(to: CGPoint(x: shaftEnd, y: shaftBottom))
            path.addLine(to: CGPoint(x: rect.minX, y: shaftBottom))
            path.closeSubpath()
        }
    }
}

private struct RegularPolygonShape: Shape {
    let sides: Int

    func path(in rect: CGRect) -> Path {
        guard sides >= 3 else { return Path() }

        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let adjustment: Double = sides == 4 ? (Double.pi / 4) : (-Double.pi / 2)

        return Path { path in
            for side in 0..<sides {
                let angle = (Double(side) * (2 * .pi / Double(sides))) + adjustment
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                )

                if side == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }
}
