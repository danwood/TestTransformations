//
//  ContentView.swift
//  TestTransformations
//
//  Created by Dan Wood on 03/03/25.
//

import SwiftUI

// MeasuredContainer
// This container uses a hidden copy (with opacity 0) to measure the untransformed bounds of its content,
// and then applies a modifier (passed in as a closure) to the visible copy.
struct MeasuredContainer<Content: View, Modified: View>: View {
	@State private var measuredFrame: CGRect = .zero
	let content: () -> Content
	let modifier: (Content, CGRect) -> Modified

	init(@ViewBuilder content: @escaping () -> Content,
		 modifier: @escaping (Content, CGRect) -> Modified) {
		self.content = content
		self.modifier = modifier
	}

	var body: some View {
		ZStack {
			// Hidden copy used solely for measuring the untransformed bounds.
			content()
				.onGeometryChange(for: CGRect.self) { proxy in
					proxy.frame(in: .global)
				} action: { newFrame in
					measuredFrame = newFrame
				}
				.opacity(0)
			// Visible copy with the modifier applied.
			modifier(content(), measuredFrame)
		}
	}
}

// CenteredTransform
// A custom GeometryEffect that builds a CGAffineTransform from our slider values.
// The transformation moves the view so that its original center is translated to a new center,
// then rotates and scales about the original center.
struct CenteredTransform: GeometryEffect {
	var offsetX: CGFloat      // Horizontal offset (slider: ±300)
	var offsetY: CGFloat      // Vertical offset (slider: ±300)
	var rotation: Angle       // Rotation angle (slider: ±90°)
	var scale: CGFloat        // Uniform scale (slider: 0...1)

	var animatableData: AnimatablePair<
		AnimatablePair<CGFloat, CGFloat>,
		AnimatablePair<CGFloat, CGFloat>
	> {
		get {
			AnimatablePair(
				AnimatablePair(offsetX, offsetY),
				AnimatablePair(CGFloat(rotation.radians), scale)
			)
		}
		set {
			offsetX = newValue.first.first
			offsetY = newValue.first.second
			rotation = Angle(radians: Double(newValue.second.first))
			scale = newValue.second.second
		}
	}

	/// Computes the projection transform by combining translation, rotation, and scaling.
	///
	/// The transformation is computed in three steps:
	/// 1. Translate so that the original center becomes the origin.
	/// 2. Apply the rotation and scaling transforms.
	/// 3. Translate to the new center.
	///
	/// - Parameter size: The size of the view being transformed.
	/// - Returns: A ProjectionTransform representing the cumulative transform.
	func effectValue(size: CGSize) -> ProjectionTransform {
		// Calculate the original center of the view.
		let originalCenter = CGPoint(x: size.width / 2, y: size.height / 2)
		// Calculate the new center by applying the user-defined offsets.
		let newCenter = CGPoint(x: originalCenter.x + offsetX, y: originalCenter.y + offsetY)

		// Step 1: Translate so that originalCenter becomes the origin.
		// (This moves the view up and to the left by half its width and height.)
		let translateToOrigin = CGAffineTransform(translationX: -originalCenter.x, y: -originalCenter.y)
		// Step 2a: Apply rotation.
		let rotateTransform = CGAffineTransform(rotationAngle: CGFloat(rotation.radians))
		// Step 2b: Apply scaling.
		let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
		// Step 3: Translate to the new center.
		let translateToNewCenter = CGAffineTransform(translationX: newCenter.x, y: newCenter.y)

		// Combine all transforms. Note: The order is important to ensure correct transformation.
		let transform = translateToOrigin
			.concatenating(rotateTransform).concatenating(scaleTransform)	// (OK to reverse these two)
			.concatenating(translateToNewCenter)
		return ProjectionTransform(transform)
	}
}

// MARK: - Views for Playing with Transformations

struct TransformConstants {
	static let horizontalRange: ClosedRange<CGFloat> = -300...300
	static let verticalRange: ClosedRange<CGFloat> = -300...300
	static let rotationRange: ClosedRange<Double> = -90...90
	static let scaleRange: ClosedRange<CGFloat> = 0.01...1

	static let textBackground = Color.yellow.opacity(0.3)
	static let controlPanelBackground = Color.white.opacity(0.8)
}

// Reusable SliderRow component
// A generic row containing a label, slider, and formatted value text.
struct SliderRow<T: BinaryFloatingPoint>: View where T.Stride: BinaryFloatingPoint {
	let title: String
	@Binding var value: T
	let range: ClosedRange<T>
	let formatter: (T) -> String

	var body: some View {
		GridRow {
			Text(title)
				.gridColumnAlignment(.trailing)
			Slider(value: $value, in: range)
				.padding(4)
			// Use the formatter closure to generate the display string.
			Text(formatter(value))
				.monospacedDigit()
				.frame(minWidth: 30, alignment: .trailing)
		}
	}
}

struct OffsetView: View {
	@State private var offsetX: CGFloat = 0
	@State private var offsetY: CGFloat = 0
	@State private var rotation: Double = 0   // in degrees
	@State private var scale: CGFloat = 1

	var body: some View {
		VStack {
			// Position "Hello world" with spacers so it's not vertically centered
			Spacer()
			Spacer()
			Text("Hello world")
				.padding()
				.background(TransformConstants.textBackground) // Background for visual clarity
				.modifier(
					CenteredTransform(
						offsetX: offsetX,
						offsetY: offsetY,
						rotation: .degrees(rotation),
						scale: scale
					)
				)
			Spacer()
			Spacer()
			Spacer()

			VStack(spacing: 10) {
				Grid(alignment: .trailing, horizontalSpacing: 4, verticalSpacing: 2) {
					// Each SliderRow uses trailing closure syntax for the formatter.
					SliderRow(title: "Horizontal Offset", value: $offsetX,
							  range: TransformConstants.horizontalRange) { String(format: "%.0f", $0) }
					SliderRow(title: "Vertical Offset", value: $offsetY,
							  range: TransformConstants.verticalRange) { String(format: "%.0f", $0) }
					SliderRow(title: "Rotation", value: $rotation,
							  range: TransformConstants.rotationRange) { String(format: "%.0f°", $0) }
					SliderRow(title: "Scale", value: $scale,
							  range: TransformConstants.scaleRange) { String(format: "%.2f", $0) }
				}
			}
			.padding(4)
			.background(TransformConstants.controlPanelBackground)

			Button("Reset") {
				withAnimation {
					offsetX = 0
					offsetY = 0
					rotation = 0
					scale = 1
				}
			}
		}
		.padding()
	}
}

struct TargetView: View {
	// The normalized target point; (0,0) is upper left, (1,1) is bottom right.
	@State private var targetPoint: CGPoint = CGPoint(x: 0.1, y: 0.1)
	@State private var rotation: Double = 0    // in degrees
	@State private var scale: CGFloat = 1

	var body: some View {
		GeometryReader { geometry in
			// Obtain the canvas's global frame.
			let canvasGlobalFrame = geometry.frame(in: .global)
			let canvasSize = geometry.size

			ZStack {
				VStack {
					Spacer()
					// MeasuredContainer to capture the original (untransformed) frame of the text.
					MeasuredContainer {
						Text("Hello world")
							.padding()
							.background(TransformConstants.textBackground)
					} modifier: { content, measuredFrame in
						// Calculate the measured center in global coordinates.
						let measuredCenter = CGPoint(x: measuredFrame.midX, y: measuredFrame.midY)
						// Compute the absolute target position in global coordinates.
						let targetGlobal = CGPoint(
							x: canvasGlobalFrame.origin.x + canvasGlobalFrame.size.width * targetPoint.x,
							y: canvasGlobalFrame.origin.y + canvasGlobalFrame.size.height * targetPoint.y
						)
						// Calculate the offset required so that measuredCenter becomes targetGlobal.
						let offsetX = targetGlobal.x - measuredCenter.x
						let offsetY = targetGlobal.y - measuredCenter.y

						return content.modifier(
							CenteredTransform(
								offsetX: offsetX,
								offsetY: offsetY,
								rotation: .degrees(rotation),
								scale: scale
							)
						)
					}
					Spacer()
					Spacer()
					Spacer()
				}

				// Draggable red "scope" icon.
				let targetLocal = CGPoint(
					x: targetPoint.x * canvasSize.width,
					y: targetPoint.y * canvasSize.height
				)
				Image(systemName: "scope")
					.resizable()
					.frame(width: 30, height: 30)
					.foregroundColor(.red)
					.position(targetLocal)
					.gesture(
						DragGesture()
							.onChanged { value in
								// Update targetPoint using the local coordinates of the drag gesture.
								let newX = min(max(value.location.x / canvasSize.width, 0), 1)
								let newY = min(max(value.location.y / canvasSize.height, 0), 1)
								targetPoint = CGPoint(x: newX, y: newY)
							}
					)
			}
			.overlay(alignment: .bottom) {
				// Control panel: sliders for targetPoint, rotation, and scale.
				VStack {
					VStack(spacing: 10) {
						Grid(alignment: .trailing, horizontalSpacing: 4, verticalSpacing: 2) {
							SliderRow(title: "Target X", value: $targetPoint.x,
									  range: 0...1) { String(format: "%.2f", $0) }
							SliderRow(title: "Target Y", value: $targetPoint.y,
									  range: 0...1) { String(format: "%.2f", $0) }
							SliderRow(title: "Rotation", value: $rotation,
									  range: TransformConstants.rotationRange) { String(format: "%.0f°", $0) }
							SliderRow(title: "Scale", value: $scale,
									  range: TransformConstants.scaleRange) { String(format: "%.2f", $0) }
						}
					}
					.padding(4)
					.background(TransformConstants.controlPanelBackground)

					Button("Reset") {
						withAnimation {
							targetPoint = CGPoint(x: 0.1, y: 0.1)
							rotation = 0
							scale = 1
						}
					}
				}
				.padding()
			}
		}
	}
}

struct ContentView: View {
	var body: some View {
		TabView {
			OffsetView()
				.tabItem {
					Label("Offset", systemImage: "arrow.left.and.right")
				}
			TargetView()
				.tabItem {
					Label("Target", systemImage: "scope")
				}
		}
	}
}

#Preview("Target View") {
	TargetView()
}

#Preview("Offset View") {
	OffsetView()
}

@main
struct TransformApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}
