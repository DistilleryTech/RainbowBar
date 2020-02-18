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
    @State var stop: Bool = false
    private let colorEmitter = ColorEmitter()
    @State var waveNodes = [WaveNode]()

    var body: some View {
        return ZStack {
            ForEach(waveNodes) { node in
                return WaveView(animationFinished: self.waveFinished, node: node)
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
            if (!self.stop) {
                let color = self.colorEmitter.getColor()
                let newNode = WaveNode(color: color, delay: 0)
                self.waveNodes.append(newNode)
            }
        }.drawingGroup().onTapGesture {
            self.stop = true
        }.onAppear {
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

struct WaveView: View {
    @State private var animated = false
    
    var animationFinished: PassthroughSubject<Void, Never>
    var node: WaveNode

    var body: some View {
        let animationDuration = waveEmitPeriod * Double(visibleWavesCount)
        return NotchWave(phase: animated ? 1.0 : 0, animationFinished: self.animationFinished, node: node).animation(Animation.easeIn(duration: animationDuration).delay(node.delay)).foregroundColor(node.color).onAppear { self.animated.toggle() }
    }
}

struct NotchWave: Shape {
    var phase: CGFloat
    var animationFinished: PassthroughSubject<Void, Never>
    var node: WaveNode

    var animatableData: CGFloat {
        get { return phase }
        set {
            phase = newValue
            node.finished = phase == 1.0
        }
    }
    
    private let topNotchCornerRadius: CGFloat = 5
    private let bottomNotchCornerRadius: CGFloat = 17

    func path(in rect: CGRect) -> Path {
        DispatchQueue.main.async {
            if self.phase >= 1.0 {
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

struct RainbowBar: View {

    var body: some View {
        VStack {
            HStack {
                WavesView().rotationEffect(.degrees(180), anchor: .center).rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                Spacer().frame(width: 170)
                WavesView().blur(radius: 1).clipShape(Rectangle())
            }.frame(height: 30)
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RainbowBar()
    }
}

