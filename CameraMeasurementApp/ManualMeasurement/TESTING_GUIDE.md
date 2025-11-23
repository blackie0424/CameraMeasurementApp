# Manual AR Measurement - Testing Guide

## Quick Start

### Accessing the Feature

1. Launch the CameraMeasurementApp
2. On the main screen, tap the **"手動測量"** (Manual Measurement) button
3. The Manual Measurement view will open in full screen

### Basic Measurement Flow

#### Step 1: Initialize AR Session

- **What to see**: Center white dot (reticle) appears
- **Status message**: "移動裝置以偵測表面"
- **Action**: Move device slowly to detect surfaces

#### Step 2: Record Start Point

- **When ready**: Tracking quality is good, surface detected
- **Action**: Tap **"開始測量"** button
- **What to see**:
  - Yellow marker appears at the point
  - Status changes to "移動裝置以選擇終點"
  - Button changes to "記錄終點"

#### Step 3: Real-time Preview

- **Action**: Move device to desired end point
- **What to see**:
  - Yellow line follows from start point to current position
  - Distance updates in real-time (in cm)
  - Line and distance update smoothly (30 FPS)

#### Step 4: Record End Point

- **Action**: Tap **"記錄終點"** button
- **What to see**:
  - Second yellow marker appears
  - Final distance displayed
  - Status shows "測量完成：XX.X cm"
  - Button changes to "重新測量"

#### Step 5: Start New Measurement

- **Action**: Tap **"重新測量"** button
- **What to see**:
  - All markers and lines cleared
  - Back to initial state
  - Ready for new measurement

---

## Test Scenarios

### Scenario 1: Basic Measurement

**Objective**: Verify complete measurement flow

**Steps**:

1. Launch feature
2. Wait for AR initialization
3. Record start point
4. Move device
5. Record end point
6. Verify distance displayed
7. Reset and repeat

**Expected Results**:

- ✅ Smooth state transitions
- ✅ Visual feedback at each step
- ✅ Accurate distance calculation
- ✅ Clean reset

### Scenario 2: Hit Test Failure

**Objective**: Verify error handling

**Steps**:

1. Launch feature
2. Point at featureless surface (blank wall)
3. Try to record point

**Expected Results**:

- ✅ Guidance message: "請移動裝置以偵測表面"
- ✅ No marker placed
- ✅ State unchanged
- ✅ Visual feedback (button animation)

### Scenario 3: Tracking Quality

**Objective**: Verify tracking monitoring

**Steps**:

1. Launch feature
2. Move device rapidly
3. Observe warnings

**Expected Results**:

- ✅ Orange warning overlay appears
- ✅ Specific guidance message (e.g., "移動過快，請放慢速度")
- ✅ Warning disappears when tracking improves

### Scenario 4: Real-time Preview Performance

**Objective**: Verify smooth updates

**Steps**:

1. Launch feature
2. Record start point
3. Move device slowly in various directions
4. Observe line and distance updates

**Expected Results**:

- ✅ Smooth 30 FPS updates
- ✅ No lag or stuttering
- ✅ Distance updates accurately
- ✅ Line follows device movement

### Scenario 5: Multiple Measurements

**Objective**: Verify reset and memory management

**Steps**:

1. Complete a measurement
2. Reset
3. Complete another measurement
4. Repeat 5-10 times

**Expected Results**:

- ✅ Each measurement works correctly
- ✅ No memory leaks
- ✅ No performance degradation
- ✅ Clean state between measurements

### Scenario 6: Edge Cases

**Objective**: Test boundary conditions

**Test Cases**:

- Very short distance (< 5cm)
- Long distance (> 5m)
- Vertical measurement
- Diagonal measurement
- Poor lighting conditions
- Featureless environment

**Expected Results**:

- ✅ Appropriate error messages for invalid cases
- ✅ Accurate measurements within valid range
- ✅ Graceful degradation in poor conditions

---

## Accuracy Verification

### Method

1. Use a physical ruler or measuring tape
2. Measure a known distance (e.g., 50cm, 1m, 2m)
3. Use the app to measure the same distance
4. Compare results

### Acceptance Criteria

- **Target Accuracy**: ± 2% error
- **Example**: For 1m (100cm) measurement:
  - Acceptable range: 98cm - 102cm

### Test Distances

- [ ] 10cm
- [ ] 25cm
- [ ] 50cm
- [ ] 1m
- [ ] 2m
- [ ] 5m

---

## Performance Checklist

### Frame Rate

- [ ] Real-time preview runs at 30+ FPS
- [ ] No visible lag or stuttering
- [ ] Smooth line updates

### Memory Usage

- [ ] No memory leaks after multiple measurements
- [ ] Memory usage stable over time
- [ ] App doesn't crash after extended use

### Battery Usage

- [ ] Reasonable battery consumption
- [ ] No excessive heating

---

## Known Limitations

### Device Requirements

- Requires ARKit-compatible device (iPhone 6s or later)
- iOS 11.0 or later
- Good lighting conditions recommended

### Environmental Requirements

- Sufficient lighting
- Textured surfaces (not blank walls)
- Stable device movement (not too fast)

### Measurement Range

- Minimum distance: 1cm
- Maximum distance: 10m
- Optimal range: 10cm - 5m

---

## Troubleshooting

### Issue: "追蹤不可用"

**Cause**: AR tracking not available
**Solution**:

- Check camera permissions
- Restart app
- Ensure device supports ARKit

### Issue: "請移動裝置以偵測表面"

**Cause**: No surface detected
**Solution**:

- Move device slowly
- Point at textured surface
- Improve lighting

### Issue: "移動過快，請放慢速度"

**Cause**: Excessive motion
**Solution**:

- Move device more slowly
- Hold device steady

### Issue: "特徵點不足"

**Cause**: Featureless environment
**Solution**:

- Point at textured surface
- Move to area with more visual features
- Improve lighting

### Issue: Inaccurate measurements

**Cause**: Poor tracking or surface detection
**Solution**:

- Ensure good lighting
- Point at clear, textured surfaces
- Hold device steady
- Wait for tracking to stabilize

---

## Reporting Issues

When reporting issues, please include:

1. Device model and iOS version
2. Lighting conditions
3. Type of surface being measured
4. Steps to reproduce
5. Expected vs actual behavior
6. Screenshots or video if possible

---

## Success Criteria

Task 7.1 is considered successful if:

- ✅ All components integrate correctly
- ✅ State transitions work as designed
- ✅ Complete measurement flow works end-to-end
- ✅ Error handling works properly
- ✅ Real-time preview is smooth (30+ FPS)
- ✅ Measurements are reasonably accurate (± 2%)
- ✅ No crashes or memory leaks
- ✅ User experience matches design specification

---

**Last Updated**: 2025-11-20  
**Version**: 1.0  
**Status**: Ready for Testing ✅
