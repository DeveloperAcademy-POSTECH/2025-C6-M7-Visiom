//
//  DrawingState.swift
//  Visiom
//
//  Created by 윤창현 on 10/28/25.
//

import SwiftUI
import Combine

class DrawingState: ObservableObject {
    @Published var isDrawingEnabled = true
    @Published var isErasingEnabled = true
    @Published var drawingColor: Color = .blue
    
    func toggleDrawing() {
        isDrawingEnabled.toggle()
    }
    
    func toggleErasing() {
        isErasingEnabled.toggle()
    }
    
    func setDrawingColor(_ color: Color) {
        drawingColor = color
    }
}
