# Implementation Plan

- [x] 1. Remove automatic detection properties from ViewController

  - Remove `objectDetector`, `measurementCalculator`, `referenceObjectManager`, `realtimeMeasurementManager` properties
  - Remove `currentMeasurementRecord`, `isCapturing`, `capturedImage`, `isRealtimeMeasurementActive` properties
  - Remove `overlayView`, `frameProcessingLogCounter`, `frameProcessingCounter`, `rendererCallCount` properties
  - _Requirements: 3.1, 3.2, 3.4_

- [x] 2. Remove automatic detection methods from ViewController

  - Remove `setupOverlayView()` method
  - Remove `startRealtimeMeasurement()`, `stopRealtimeMeasurement()` methods
  - Remove `handleRealtimeMeasurementUpdate(_:)`, `handleRealtimeMeasurementError(_:)` methods
  - Remove `processARFrameForRealtimeMeasurement(_:)` method
  - _Requirements: 3.1, 3.2, 5.4, 5.5_

- [x] 3. Remove capture button functionality from ViewController

  - Remove `captureButtonTapped(_:)` IBAction method
  - Remove `performMeasurement()` method
  - Remove `captureARFrame(completion:)` method
  - Remove `imageFromARFrame(_:)` method
  - Remove `processCapturedImage(_:)` method
  - _Requirements: 3.1, 5.3_

- [x] 4. Remove results navigation from ViewController

  - Remove `showResults(with:)` method
  - Remove `prepare(for:sender:)` logic for "showResults" segue
  - _Requirements: 3.1_

- [x] 5. Remove ARSCNViewDelegate frame processing methods

  - Remove or simplify `renderer(_:updateAtTime:)` method (remove frame processing logic)
  - Remove or simplify `session(_:didUpdate:)` method (remove frame processing logic)
  - Keep AR session error handling methods (`session(_:didFailWithError:)`, `sessionWasInterrupted(_:)`, `sessionInterruptionEnded(_:)`)
  - _Requirements: 3.1, 5.5_

- [x] 6. Remove ARManagerDelegate automatic detection methods

  - Remove real-time measurement start logic from `arManager(_:didDetectPlane:)`
  - Remove real-time measurement stop logic from `arManager(_:didChangeTrackingState:)`
  - Remove real-time measurement stop logic from `arManagerSessionWasInterrupted(_:)`
  - Remove real-time measurement restart logic from `arManagerSessionInterruptionEnded(_:)`
  - Keep basic AR status updates and guidance messages
  - _Requirements: 3.1, 5.5_

- [x] 7. Simplify setupCameraMeasurement method

  - Remove initialization of `objectDetector`, `measurementCalculator`, `referenceObjectManager`
  - Remove initialization of `realtimeMeasurementManager` and its configuration
  - Remove call to `setupOverlayView()`
  - Keep ARManager initialization
  - _Requirements: 3.2, 5.6_

- [ ] 8. Simplify viewWillDisappear method

  - Remove call to `stopRealtimeMeasurement()`
  - Keep call to `stopARSession()`
  - _Requirements: 3.1_

- [ ] 9. Remove capture button from Main.storyboard

  - Remove `captureButton` UI element
  - Remove `captureButtonOutlet` connection
  - Remove `captureAction` connection
  - Remove all constraints related to capture button
  - _Requirements: 1.2, 3.3_

- [ ] 10. Remove measurement overlay from Main.storyboard

  - Remove `measurementOverlay` view element
  - Remove `measurementOverlayOutlet` connection
  - Remove all constraints related to measurement overlay
  - _Requirements: 1.3, 3.3_

- [ ] 11. Remove results segue from Main.storyboard

  - Remove `showResults` segue (identifier: "showResults")
  - Remove `showResultsSegue` connection
  - _Requirements: 3.3_

- [ ]\* 12. Verify manual measurement functionality

  - Test that manual measurement button is visible and functional
  - Test navigation to ManualMeasurementViewController
  - Test that manual measurement can perform measurements correctly
  - Test navigation back from manual measurement
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.5, 5.6_

- [ ]\* 13. Verify AR infrastructure is intact

  - Test that ARManager initializes correctly
  - Test that AR session starts and stops correctly
  - Test that AR tracking state updates work
  - Test that AR error handling works
  - _Requirements: 5.1, 5.6_

- [ ]\* 14. Verify UI cleanup

  - Verify capture button is not visible
  - Verify measurement overlay is not visible
  - Verify main screen shows only manual measurement button, settings button, status label, and guidance label
  - Test on different device sizes and orientations
  - _Requirements: 1.1, 1.2, 1.3, 4.1, 4.2, 4.3, 4.4_

- [ ]\* 15. Verify settings and guidance functionality
  - Test settings button navigation
  - Test that settings changes work correctly
  - Test that guidance messages display correctly
  - Test that guidance can be shown and hidden
  - _Requirements: 4.3_
