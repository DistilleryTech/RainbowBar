//
//  ContentView.swift
//  RainbowBarExample
//
//  Created by Alex Kubarev on 07.02.2020.
//  Copyright © 2020 Distillery. All rights reserved.
//

import SwiftUI
import Combine
import DeviceKit

public struct RainbowBar: View {
    var waveEmitPeriod: Double
    var visibleWavesCount: Int
    var waveColors: [Color]
    var backgroundColor: Color
    
    var height: CGFloat
    var centerSpacing: CGFloat
    var waveTopCornerRadius: CGFloat
    var waveBottomCornerRadius: CGFloat

    var animated: PassthroughSubject<Bool, Never>
    
    public var body: some View {
        return HStack {
//            WavesView(waveEmitPeriod: waveEmitPeriod,
//                      visibleWavesCount: visibleWavesCount,
//                      waveColors: waveColors,
//                      backgroundColor: backgroundColor,
//                      topCornerRadius: waveTopCornerRadius,
//                      bottomCornerRadius: waveBottomCornerRadius,
//                      animatedSignal: animated)
//                .blur(radius: 1)
//                .clipShape(Rectangle())
//                .rotationEffect(.degrees(180), anchor: .center)
//                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
            Spacer().frame(width: centerSpacing)
            WavesView(waveEmitPeriod: waveEmitPeriod,
                      visibleWavesCount: visibleWavesCount,
                      waveColors: waveColors,
                      backgroundColor: backgroundColor,
                      topCornerRadius: waveTopCornerRadius,
                      bottomCornerRadius: waveBottomCornerRadius,
                      animatedSignal: animated)
                .blur(radius: 1)
                .clipShape(Rectangle())
        }.frame(height: height)
    }
    
    public init(waveEmitPeriod: Double,
                visibleWavesCount: Int,
                waveColors: [Color],
                backgroundColor: Color,
                animated: PassthroughSubject<Bool, Never>,
                height: Size = defaultSize(),
                centerSpacing: Size = defaultSize(),
                waveTopCornerRadius: Size = defaultSize(),
                waveBottomCornerRadius: Size = defaultSize()) {
        self.waveEmitPeriod = waveEmitPeriod
        self.visibleWavesCount = visibleWavesCount
        self.waveColors = waveColors
        self.backgroundColor = backgroundColor
        self.animated = animated
        
        let nonNotchedStatusBarHeight: CGFloat = 20.0

        switch height {
        case .none:
            self.height = nonNotchedStatusBarHeight
        case .small:
            self.height = 30
        case .big:
            self.height = 33
        case .custom(let val):
            self.height = val
        }
        
        switch centerSpacing {
        case .none:
            self.centerSpacing = 0
        case .small:
            self.centerSpacing = 117
        case .big:
            self.centerSpacing = 128
        case .custom(let val):
            self.centerSpacing = val
        }

        let nonNotchedStatusBarHalfHeight: CGFloat = nonNotchedStatusBarHeight / 2
        
        switch waveTopCornerRadius {
        case .none:
            self.waveTopCornerRadius = nonNotchedStatusBarHalfHeight
        case .small:
            self.waveTopCornerRadius = 6
        case .big:
            self.waveTopCornerRadius = 7
        case .custom(let val):
            self.waveTopCornerRadius = val
        }
        
        switch waveBottomCornerRadius {
        case .none:
            self.waveBottomCornerRadius = nonNotchedStatusBarHalfHeight
        case .small:
            self.waveBottomCornerRadius = 20
        case .big:
            self.waveBottomCornerRadius = 21
        case .custom(let val):
            self.waveBottomCornerRadius = val
        }
    }
}

struct WavesView: View {
    let waveEmitPeriod: Double
    let visibleWavesCount: Int
    let waveColors: [Color]
    let backgroundColor: Color
    var topCornerRadius, bottomCornerRadius: CGFloat
    
    private let colorEmitter = ColorEmitter()
    private let waveFinished = PassthroughSubject<Void, Never>()
    @State private var waveNodes = [WaveNode]()
    @State private var animatedInnerState: Bool = false {
        didSet {
            if animatedInnerState {
                var res = [NotchWaveNode]()
                for index in 0..<visibleWavesCount {
                    guard let color = self.colorEmitter.nextColor(from: self.waveColors) else { continue }
                    let newNode = NotchWaveNode(color: color,
                                                delay: waveEmitPeriod * Double(index))
                    res.append(newNode)
                }
                waveNodes = res
            } else {
                waveNodes.removeAll {
                    !$0.started
                }
                if let lastVisibleNode = waveNodes.last as? NotchWaveNode {
                    let gradientNode = GradientWaveNode(frontColor: lastVisibleNode.color,
                                                        backColor: backgroundColor,
                                                        delay: 0)
                    waveNodes.append(gradientNode)
                }
            }
        }
    }
    @State var animatedSignal = PassthroughSubject<Bool, Never>()
    
    var body: some View {
        return ZStack {
            ForEach(waveNodes) { node in
                WaveView(animationDuration: self.waveEmitPeriod * Double(self.visibleWavesCount),
                         animationFinished: self.waveFinished,
                         node: node,
                         topCornerRadius: self.topCornerRadius,
                         bottomCornerRadius: self.bottomCornerRadius)
            }
        }.onReceive(waveFinished) {
            // remove invisible (lower, first) node?
            if self.waveNodes.count > 0 {
                var removeFirstNode = false
                if self.waveNodes.count > 1 {
                    removeFirstNode = self.waveNodes[1].finished
                }
                if removeFirstNode {
                    self.waveNodes.removeFirst()
                }
            }
            
            //add new color (node)
            if self.animatedInnerState, let color = self.colorEmitter.nextColor(from: self.waveColors) {
                let newNode = NotchWaveNode(color: color, delay: 0)
                self.waveNodes.append(newNode)
            }
        }.onReceive(animatedSignal) { animated in
            self.animatedInnerState = animated
        }.drawingGroup()
    }
}

struct WaveView: View {
    var animationDuration: Double
    var animationFinished: PassthroughSubject<Void, Never>
    var node: WaveNode
    var topCornerRadius, bottomCornerRadius: CGFloat

    @State private var animated: Bool = false
    
    func makeWave(from node: WaveNode) -> some View {
        let phase: CGFloat = self.animated ? 1.0 : 0.0
        if let notchNode = node as? NotchWaveNode {
            return AnyView(NotchWave(phase: phase,
                                     animationFinished: self.animationFinished,
                                     node: notchNode,
                                     topCornerRadius: topCornerRadius,
                                     bottomCornerRadius: bottomCornerRadius).foregroundColor(notchNode.color))
        } else if let gradientNode = node as? GradientWaveNode {
            return AnyView(GradientWave(phase: phase,
                                        frontColor: gradientNode.frontColor,
                                        backColor: gradientNode.backColor,
                                        animationFinished: self.animationFinished,
                                        minWidth: topCornerRadius + bottomCornerRadius))
        } else {
            return AnyView(EmptyView())
        }
    }
    
    var body: some View {
        return makeWave(from: node).animation(Animation.easeIn(duration: animationDuration).delay(node.delay)).onAppear {
            self.animated.toggle()
        }
    }
}

// MARK: - Waves

struct NotchWave: Shape {
    var phase: CGFloat
    var animationFinished: PassthroughSubject<Void, Never>
    var node: NotchWaveNode
    var topCornerRadius, bottomCornerRadius: CGFloat

    var animatableData: CGFloat {
        get { return phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        if !self.node.started && self.phase > 0.0 {
            self.node.started = true
        }
        
        DispatchQueue.main.async {
            if self.phase >= 1.0 {
                self.node.finished = true
                self.animationFinished.send()
            }
        }
        
        var p = Path()
        
        p.move(to: CGPoint.zero)
        
        let currentWidth = 2 * (topCornerRadius + bottomCornerRadius) + rect.size.width * phase
        p.addLine(to: CGPoint(x: currentWidth, y: 0))
        
        let topArcCenter = CGPoint(x: currentWidth, y: topCornerRadius)
        p.addArc(center: topArcCenter, radius: topCornerRadius, startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)

        let height = rect.size.height
        p.addLine(to: CGPoint(x: currentWidth - topCornerRadius, y: height - bottomCornerRadius))

        let bottomArcCenter = CGPoint(x: currentWidth - topCornerRadius - bottomCornerRadius, y: height - bottomCornerRadius)
        p.addArc(center: bottomArcCenter, radius: bottomCornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        
        p.addLine(to: CGPoint(x: 0, y: height))

        p.closeSubpath()
        
        return p
    }
}

struct GradientWave: View {
    var phase: CGFloat
    var frontColor, backColor: Color
    var animationFinished: PassthroughSubject<Void, Never>
    var minWidth: CGFloat

    var animatableData: CGFloat {
        get { return phase }
        set { phase = newValue }
    }
    
    var body: some View {
        DispatchQueue.main.async {
            if self.phase >= 1.0 {
                self.animationFinished.send()
            }
        }
        
        return GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle().foregroundColor(self.backColor).frame(width: (geometry.size.width + self.minWidth) * self.phase)
                LinearGradient(gradient: Gradient(colors: [self.backColor, self.frontColor]),
                               startPoint: .leading,
                               endPoint: .trailing).frame(width: self.minWidth)
                Spacer()
            }
        }
    }
}

// MARK: - Model

class WaveNode: Identifiable, Equatable {
    let id = UUID()
    let delay: Double

    var started: Bool = false
    var finished: Bool = false
    
    init(delay: Double) {
        self.delay = delay
    }
    
    static func ==(lhs: WaveNode, rhs: WaveNode) -> Bool {
        return lhs.id == rhs.id
    }
}

class NotchWaveNode: WaveNode {
    let color: Color
    
    init(color: Color, delay: Double) {
        self.color = color
        super.init(delay: delay)
    }
}

class GradientWaveNode: WaveNode {
    let frontColor, backColor: Color
    
    init(frontColor: Color, backColor: Color, delay: Double) {
        self.frontColor = frontColor
        self.backColor = backColor
        super.init(delay: delay)
    }
}


// MARK: - Misc

class ColorEmitter {
    var colors, refColors: [Color]?
    
    func nextColor(from newColors: [Color]) -> Color? {
        if !(refColors?.elementsEqual(newColors) ?? false) {
            colors = newColors
            refColors = newColors
        }
        
        let res = colors?.removeFirst()
        if let res = res {
            colors?.append(res)
        }
        return res
    }
}

public enum Size {
    case none
    case small
    case big
    case custom(CGFloat)
}

public func defaultSize() -> Size {
    switch Device.current {
    case .iPhoneX,
         .simulator(.iPhoneX),
         .iPhoneXS,
         .simulator(.iPhoneXS),
         .iPhoneXSMax,
         .simulator(.iPhoneXSMax),
         .iPhone11Pro,
         .simulator(.iPhone11Pro),
         .iPhone11ProMax,
         .simulator(.iPhone11ProMax):
        return .small
    case .iPhoneXR,
         .simulator(.iPhoneXR),
         .iPhone11,
         .simulator(.iPhone11):
        return .big
    default:
        return .none
    }
}
