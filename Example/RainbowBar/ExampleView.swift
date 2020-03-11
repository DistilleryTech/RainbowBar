//
//  ExampleView.swift
//  RainbowBarExample
//
//  Created by Alex Kubarev on 04.03.2020.
//  Copyright © 2020 Distillery. All rights reserved.
//

import SwiftUI
import Combine
import RainbowBar

func notchHeight() -> CGFloat {
    switch DeviceDependentOptions.notchSize {
    case .small:
        return 30
    case .big:
        return 33
    case .none:
        return nonNotchedStatusBarHeight
    }
}

struct ExampleView: View {
    private var animatedSignal = PassthroughSubject<Bool, Never>()
    @State private var animatedInnerState: Bool = false

    var body: some View {
        return VStack {
            RainbowBar(waveEmitPeriod: 0.3,
                       visibleWavesCount: 3,
                       waveColors: [.red, .green, .blue],
                       backgroundColor: .white,
                       animated: animatedSignal).frame(height: notchHeight())
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

