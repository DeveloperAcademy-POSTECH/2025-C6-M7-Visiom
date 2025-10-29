//
//  DrawingControlView.swift
//  Visiom
//
//  Created by 윤창현 on 10/28/25.
//
import SwiftUI

struct DrawingControlView: View {
    @EnvironmentObject var drawingState: DrawingState
    
    var body: some View {
        VStack(spacing: 12) {
            // 그리기 토글 버튼
            Toggle(isOn: $drawingState.isDrawingEnabled) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18))
                    Text("그리기")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .onChange(of: drawingState.isDrawingEnabled) { enabled in
                DrawingSystem.setDrawingEnabled(enabled)
            }
            .tint(.blue)
            .padding(.horizontal, 16)
            
            // 지우기 토글 버튼
            Toggle(isOn: $drawingState.isErasingEnabled) {
                HStack {
                    Image(systemName: "eraser.fill")
                        .font(.system(size: 18))
                    Text("지우기")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .onChange(of: drawingState.isErasingEnabled) { enabled in
                DrawingSystem.setErasingEnabled(enabled)
            }
            .tint(.red)
            .padding(.horizontal, 16)
            
            // 색상 선택
            HStack(spacing: 12) {
                Text("색상")
                    .font(.system(size: 14, weight: .semibold))
                
                ColorPickerButton(color: .blue, isSelected: drawingState.drawingColor == .blue) {
                    drawingState.setDrawingColor(.blue)
                    DrawingSystem.setDrawingColor(.systemBlue)
                }
                
                ColorPickerButton(color: .red, isSelected: drawingState.drawingColor == .red) {
                    drawingState.setDrawingColor(.red)
                    DrawingSystem.setDrawingColor(.systemRed)
                }
                
                ColorPickerButton(color: .green, isSelected: drawingState.drawingColor == .green) {
                    drawingState.setDrawingColor(.green)
                    DrawingSystem.setDrawingColor(.systemGreen)
                }
                
                ColorPickerButton(color: .yellow, isSelected: drawingState.drawingColor == .yellow) {
                    drawingState.setDrawingColor(.yellow)
                    DrawingSystem.setDrawingColor(.systemYellow)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // 전체 지우기 버튼
            Button(action: {
                NotificationCenter.default.post(name: NSNotification.Name.clearAllDrawing, object: nil)
            }) {
                HStack {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 18))
                    Text("전체 지우기")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
        }
        .frame(width: 300, height: 300)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
        .padding(16)
    }
}

struct ColorPickerButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                )
        }
    }
}

#Preview {
    DrawingControlView()
        .environmentObject(DrawingState())
}
