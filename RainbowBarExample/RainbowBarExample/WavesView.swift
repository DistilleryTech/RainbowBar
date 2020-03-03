//
//  ContentView.swift
//  RainbowBarExample
//
//  Created by Alex Kubarev on 07.02.2020.
//  Copyright © 2020 Distillery. All rights reserved.
//

import SwiftUI
import Combine
import Device

let waveEmitPeriod: Double = 0.66
let visibleWavesCount: Int = 3
let waveColors: [Color] = [.red, .green, .blue]
let backgroundColor: Color = .white

class ColorEmitter {
    private var colors: [Color] = waveColors
    
    func getColor() -> Color {
        let res = colors.removeFirst()
        colors.append(res)
        return res
    }
}

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

struct WavesView: View {
    private let waveFinished = PassthroughSubject<Void, Never>()
    private let colorEmitter = ColorEmitter()
    @State private var waveNodes = [WaveNode]()
    @State private var animatedInnerState: Bool = false {
        didSet {
            if animatedInnerState {
                var res = [NotchWaveNode]()
                for index in 0..<visibleWavesCount {
                    let color = self.colorEmitter.getColor()
                    let newNode = NotchWaveNode(color: color, delay: waveEmitPeriod * Double(index))
                    res.append(newNode)
                }
                self.waveNodes =  res
            } else {
                waveNodes.removeAll {
                    !$0.started
                }
                if let lastVisibleNode = waveNodes.last as? NotchWaveNode {
                    let gradientNode = GradientWaveNode(frontColor: lastVisibleNode.color, backColor: backgroundColor, delay: 0)
                    waveNodes.append(gradientNode)
                }
            }
        }
    }
    @State var animatedSignal = PassthroughSubject<Bool, Never>()
    
    var body: some View {
        return ZStack {
            ForEach(waveNodes) { node in
                WaveView(animationFinished: self.waveFinished, node: node)
            }
        }.onReceive(waveFinished) {node in
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
            if (self.animatedInnerState) {
                let color = self.colorEmitter.getColor()
                let newNode = NotchWaveNode(color: color, delay: 0)
                self.waveNodes.append(newNode)
            }
        }.onReceive(animatedSignal) { animated in
            self.animatedInnerState = animated
        }.drawingGroup()
    }
}

struct WaveView: View {
    var animationFinished: PassthroughSubject<Void, Never>
    var node: WaveNode

    @State private var animated: Bool = false
    
    func makeWave(from node: WaveNode) -> some View {
        let phase: CGFloat = self.animated ? 1.0 : 0.0
        if let notchNode = node as? NotchWaveNode {
            return AnyView(NotchWave(phase: phase, animationFinished: self.animationFinished, node: notchNode).foregroundColor(notchNode.color))
        } else if let gradientNode = node as? GradientWaveNode {
            return AnyView(GradientWave(phase: phase, frontColor: gradientNode.frontColor, backColor: gradientNode.backColor, animationFinished: self.animationFinished))
        } else {
            return AnyView(EmptyView())
        }
    }
    
    var body: some View {
        let animationDuration = waveEmitPeriod * Double(visibleWavesCount)
        return makeWave(from: node).animation(Animation.easeIn(duration: animationDuration).delay(node.delay)).onAppear {
            self.animated.toggle()
        }
    }
}

struct RainbowBar: View {
    @State var animated = PassthroughSubject<Bool, Never>()
    
    var body: some View {
        return HStack {
            WavesView(animatedSignal: animated).rotationEffect(.degrees(180), anchor: .center).rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
            Spacer().frame(width: DeviceDependentOptions.notchWidth)
            WavesView(animatedSignal: animated).blur(radius: 1).clipShape(Rectangle())
        }
    }
}

struct ExampleView: View {
    private var animatedSignal = PassthroughSubject<Bool, Never>()
    @State private var animatedInnerState: Bool = false

    var body: some View {
        return VStack {
            RainbowBar(animated: animatedSignal).frame(height: DeviceDependentOptions.notchHeight)
            Spacer()
            Button(action: {
                self.animatedInnerState.toggle()
                self.animatedSignal.send(self.animatedInnerState)
            }) {
                Text("Toggle")
            }
            Spacer()
        }.edgesIgnoringSafeArea(.all)
    }
}


enum NotchSize {
    case none
    case small
    case big
}

class DeviceDependentOptions {
    static private let nonNotchedStatusBarHeight: CGFloat = 20.0
    static private let nonNotchedStatusBarHalfHeight: CGFloat = nonNotchedStatusBarHeight / 2
    
    static var notchSize: NotchSize {
        switch Device.size() {
        case .screen5_8Inch, .screen6_5Inch:
            return .small
        case .screen6_1Inch:
            return .big
        default:
            return .none
        }
    }
    
    static var topNotchCornerRadius: CGFloat {
        switch notchSize {
        case .none:
            return nonNotchedStatusBarHalfHeight
        case .small:
            return 6.0
        case .big:
            return 7.0
        }
    }
    
    static var bottomNotchCornerRadius: CGFloat {
        switch notchSize {
        case .none:
            return nonNotchedStatusBarHalfHeight
        case .small:
            return 20.0
        case .big:
            return 21.0
        }
    }
    
    static var minWidth: CGFloat {
        return topNotchCornerRadius + bottomNotchCornerRadius
    }
    
    static var notchHeight: CGFloat {
        switch notchSize {
        case .none:
            return nonNotchedStatusBarHeight
        case .small:
            return 30
        case .big:
            return 33
        }
    }
    
    static var notchWidth: CGFloat {
        switch notchSize {
        case .none:
            return 0
        case .small:
            return 117
        case .big:
            return 128
        }
    }
}

struct NotchWave: Shape {
    var phase: CGFloat
    var animationFinished: PassthroughSubject<Void, Never>
    var node: NotchWaveNode

    var animatableData: CGFloat {
        get { return phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        DispatchQueue.main.async {
            if !self.node.started && self.phase > 0.0 {
                self.node.started = true
            }
            if self.phase >= 1.0 {
                self.node.finished = true
                self.animationFinished.send()
            }
        }
        
        var p = Path()
        
        p.move(to: CGPoint.zero)
                
        let currentWidth = 2 * DeviceDependentOptions.minWidth + rect.size.width * phase
        p.addLine(to: CGPoint(x: currentWidth, y: 0))
        
        let topArcCenter = CGPoint(x: currentWidth, y: DeviceDependentOptions.topNotchCornerRadius)
        p.addArc(center: topArcCenter, radius: DeviceDependentOptions.topNotchCornerRadius, startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)

        let height = rect.size.height
        p.addLine(to: CGPoint(x: currentWidth - DeviceDependentOptions.topNotchCornerRadius, y: height - DeviceDependentOptions.bottomNotchCornerRadius))

        let bottomArcCenter = CGPoint(x: currentWidth - DeviceDependentOptions.topNotchCornerRadius - DeviceDependentOptions.bottomNotchCornerRadius, y: height - DeviceDependentOptions.bottomNotchCornerRadius)
        p.addArc(center: bottomArcCenter, radius: DeviceDependentOptions.bottomNotchCornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        
        p.addLine(to: CGPoint(x: 0, y: height))

        p.closeSubpath()
        
        return p
    }
}

struct GradientWave: View {
    var phase: CGFloat
    var frontColor, backColor: Color
    var animationFinished: PassthroughSubject<Void, Never>

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
                Rectangle().foregroundColor(self.backColor).frame(width: (geometry.size.width + DeviceDependentOptions.minWidth) * self.phase)
                LinearGradient(gradient: Gradient(colors: [self.backColor, self.frontColor]), startPoint: .leading, endPoint: .trailing).frame(width: DeviceDependentOptions.minWidth)
                Spacer()
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }
}
