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
import Device

func notchHeight() -> CGFloat {
    switch Device.size() {
    case .screen5_8Inch, .screen6_5Inch:
        return 30
    case .screen6_1Inch:
        return 33
    default:
        return 20
    }
}

struct ExampleView: View {
    private var animatedSignal = PassthroughSubject<Bool, Never>()
    @State private var animatedInnerState: Bool = false

    var body: some View {
        return VStack {
            RainbowBar(waveEmitPeriod: 0.3, animated: animatedSignal).frame(height: notchHeight())
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

