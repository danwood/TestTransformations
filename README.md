# TestTransformations

TestTransformations is a very small open-source SwiftUI project that demonstrates how to precisely reposition, rotate, and scale a view using custom transformations. The project is designed to test and verify the ability to render a SwiftUI view at a different location while applying rotation and scaling without disrupting the view’s center alignment.

## Overview

This project focuses on applying a CGAffineTransform to a SwiftUI view in such a way that the translation (moving the center point) is maintained even when the view is rotated and scaled. It includes:

- **MeasuredContainer:** A container view that uses a hidden copy of its content to accurately measure the view’s original (untransformed) bounds.
- **CenteredTransform:** A custom `GeometryEffect` that constructs a CGAffineTransform. This transform:
  1. Translates the view so that its original center is moved to the origin.
  2. Applies rotation and scaling.
  3. Translates the view to a new center.

This ordering ensures that the rotation and scaling do not interfere with the precise translation of the view's center.

## Key Features

- **Interactive Controls:** Two main views (Offset and Target) allow users to adjust translation offsets, rotation angles, and scaling factors using intuitive sliders and gestures.
- **Accurate Transformation:** The project builds the CGAffineTransform in the right order to ensure that the view’s center is correctly repositioned, regardless of the rotation and scale applied.
- **Dynamic Measurement:** By leveraging a hidden copy for measurement, the project ensures that the transformation calculations are based on the true dimensions of the view.

## How It Works

The transformation is applied in a three-step process:
1. **Centering Translation:** The view is first translated so that its original center is moved to the origin.
2. **Rotation & Scaling:** The view is then rotated and scaled about this origin.
3. **Final Translation:** Finally, the view is translated again to the new target center. 

This process guarantees that the center point remains consistent, and the applied transformations are predictable.

## Usage

The app offers two primary tabs:
- **Offset View**: Adjust horizontal and vertical offsets, rotation, and scale using sliders. This view demonstrates how to directly reposition and transform the “Hello world” text.
- **Target View**: Use a draggable “scope” icon to set a target position. The app calculates the necessary offset to reposition the view’s center, while also allowing rotation and scaling adjustments. You should see the “Hello world” behind the scope at all times, as it tracks in real-time.


