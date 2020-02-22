//
//  ContentView.swift
//  RainbowBarExample
//
//  Created by Alex Kubarev on 07.02.2020.
//  Copyright © 2020 Distillery. All rights reserved.
//

import SwiftUI
import Combine

let waveEmitPeriod: Double = 0.66
let visibleWavesCount: Int = 3
let waveColors: [Color] = [.red, .green, .blue]

class ColorEmitter {
    private var colors: [Color] = waveColors
    
    func getColor() -> Color {
        let res = colors.removeFirst()
        colors.append(res)
        return res
    }
}

class WaveNode: Identifiable {
    let id = UUID()
    
    let color: Color
    let delay: Double
    var finished: Bool = false
    
    init(color: Color, delay: Double) {
        self.color = color
        self.delay = delay
    }
}

struct WavesView: View {
    @State private var waveFinished = PassthroughSubject<Void, Never>()
    private let colorEmitter = ColorEmitter()
    @State private var waveNodes = [WaveNode]()
    @State private var animatedInnerState: Bool = false {
        didSet {
            print("animatedInnerState didSet to \(animatedInnerState)")
            if animatedInnerState {
                var res = [WaveNode]()
                for index in 0..<visibleWavesCount {
                    let color = self.colorEmitter.getColor()
                    let newNode = WaveNode(color: color, delay: waveEmitPeriod * Double(index))
                    res.append(newNode)
                }
                self.waveNodes =  res
            }
        }
    }
    var animatedSignal = PassthroughSubject<Bool, Never>()

//    func makeWave(node: WaveNode) -> WaveView {
//        print("makeWave: nodes = \(waveNodes.count)")
//        return WaveView(animated: self.$animatedInnerState, animationFinished: self.waveFinished, node: node)
//    }

    var body: some View {
        return ZStack {
            ForEach(waveNodes) { node in
//                self.makeWave(node: node)
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
                let newNode = WaveNode(color: color, delay: 0)
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
    
    var body: some View {
        let animationDuration = waveEmitPeriod * Double(visibleWavesCount)
        print("WaveView body: dur = \(animationDuration) color = \(node.color)")
        return NotchWave(phase: animated ? 1.0 : 0, animationFinished: self.animationFinished, node: node).animation(Animation.easeIn(duration: animationDuration).delay(node.delay)).foregroundColor(node.color).onAppear {
            self.animated.toggle()
        }
    }
}

struct RainbowBar: View {
    private var animatedSignal = PassthroughSubject<Bool, Never>()
    @State private var animatedInnerState: Bool = false

    var body: some View {
        VStack {
            HStack {
                WavesView(animatedSignal: animatedSignal).rotationEffect(.degrees(180), anchor: .center).rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                Spacer().frame(width: 170)
                WavesView(animatedSignal: animatedSignal).blur(radius: 1).clipShape(Rectangle())
            }.frame(height: 30)
            Spacer()
            Button(action: {
                self.animatedInnerState.toggle()
                self.animatedSignal.send(self.animatedInnerState)
            }) {
                Text("Toggle")
            }
            Spacer()
        }
    }
}

struct NotchWave: Shape {
    var phase: CGFloat
    var animationFinished: PassthroughSubject<Void, Never>
    var node: WaveNode

    var animatableData: CGFloat {
        get { return phase }
        set {
            print("animatable \(newValue)")
            phase = newValue
        }
    }
    
    private let topNotchCornerRadius: CGFloat = 5
    private let bottomNotchCornerRadius: CGFloat = 17

    func path(in rect: CGRect) -> Path {
        DispatchQueue.main.async {
            if self.phase >= 1.0 {
                self.node.finished = true
                self.animationFinished.send()
            }
        }
        
        var p = Path()
        
        p.move(to: CGPoint.zero)
        
        let minWidth = topNotchCornerRadius + bottomNotchCornerRadius
        
        let currentWidth = minWidth + rect.size.width * phase
        p.addLine(to: CGPoint(x: currentWidth, y: 0))
        
        let topArcCenter = CGPoint(x: currentWidth, y: topNotchCornerRadius)
        p.addArc(center: topArcCenter, radius: topNotchCornerRadius, startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)

        let height = rect.size.height
        p.addLine(to: CGPoint(x: currentWidth - topNotchCornerRadius, y: height - bottomNotchCornerRadius))

        let bottomArcCenter = CGPoint(x: currentWidth - topNotchCornerRadius - bottomNotchCornerRadius, y: height - bottomNotchCornerRadius)
        p.addArc(center: bottomArcCenter, radius: bottomNotchCornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        
        p.addLine(to: CGPoint(x: 0, y: height))

        p.closeSubpath()
        
        return p
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RainbowBar()
    }
}
