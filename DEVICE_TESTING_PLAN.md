# NaviGPT Device Testing Plan (Option B)

**Goal**: Validate real-world performance, accuracy, and usability of NaviGPT with actual LiDAR hardware and accessibility features.

**Duration**: 2-3 days of structured testing
**Requirements**: iPhone 12 Pro or newer (LiDAR sensor required)

---

## Phase 1: Device Setup & Deployment (30 minutes)

### 1.1 Prerequisites
- [ ] iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro, or 16 Pro (LiDAR required)
- [ ] macOS with Xcode 14+
- [ ] Apple Developer Account (free or paid)
- [ ] USB-C or Lightning cable
- [ ] Latest iOS version installed

### 1.2 Device Provisioning

#### Step 1: Connect Device
```bash
# Check connected devices
xcrun xctrace list devices

# Should show your iPhone in the list
```

#### Step 2: Trust Computer
1. Connect iPhone to Mac via cable
2. On iPhone: Tap "Trust" when prompted
3. Enter device passcode

#### Step 3: Configure Signing in Xcode
1. Open `NaviGPT.xcodeproj` in Xcode
2. Select NaviGPT target
3. Go to "Signing & Capabilities" tab
4. Check "Automatically manage signing"
5. Select your Team (Personal Team or Developer Team)
6. Xcode will automatically create provisioning profile

#### Step 4: Build for Device
```bash
# Build and install on connected device
xcodebuild build -project NaviGPT_build_from_here/NaviGPT.xcodeproj \
  -scheme Intern1 \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates
```

Or in Xcode:
1. Select your physical device from scheme menu (top left)
2. Product → Run (Cmd+R)

### 1.3 Permissions Setup
On first launch, grant these permissions:
- [ ] Camera Access (Required for vision processing)
- [ ] Location Services (Required for navigation)
- [ ] Microphone (Required for voice commands)
- [ ] Motion & Fitness (Helpful for movement tracking)

---

## Phase 2: Core Functionality Testing (2-3 hours)

### 2.1 LiDAR Sensor Validation

**Test Location**: Indoor space with varied obstacles

| Test Case | Steps | Expected Result | Pass/Fail | Notes |
|-----------|-------|-----------------|-----------|-------|
| LiDAR Initialization | Launch app → Enable camera view | LiDAR depth overlay appears | [ ] | |
| Depth Map Quality | Point at objects 1-5m away | Smooth depth gradient visible | [ ] | |
| Obstacle Detection | Walk toward wall/furniture | Detects obstacle before 2m | [ ] | |
| Multi-Object Tracking | Multiple objects in view | Tracks all simultaneously | [ ] | |
| Moving Obstacles | Have someone walk across view | Tracks moving person | [ ] | |

**Metrics to Record**:
- Average depth map refresh rate: ______ Hz
- Obstacle detection latency: ______ ms
- Max tracking distance: ______ meters

### 2.2 YOLOv8 Object Detection

**Test Location**: Various environments (indoor, outdoor, mixed)

| Object Type | Test Scenario | Detection Success | Confidence Score | Distance |
|-------------|---------------|-------------------|------------------|----------|
| **People** | Person standing still 3m away | [ ] | ___% | ___m |
| | Person walking | [ ] | ___% | ___m |
| | Multiple people (2-5) | [ ] | ___% | ___m |
| **Vehicles** | Parked car | [ ] | ___% | ___m |
| | Bicycle | [ ] | ___% | ___m |
| | Moving vehicle (safe distance) | [ ] | ___% | ___m |
| **Street Furniture** | Traffic sign | [ ] | ___% | ___m |
| | Fire hydrant | [ ] | ___% | ___m |
| | Bench | [ ] | ___% | ___m |
| **Indoor Objects** | Chair | [ ] | ___% | ___m |
| | Table | [ ] | ___% | ___m |
| | Door | [ ] | ___% | ___m |

**Success Criteria**:
- Detection rate: >80% for common objects
- Confidence threshold: >50% for clear objects
- False positive rate: <10%

### 2.3 Audio Feedback System

**Test Location**: Quiet indoor space, then noisy outdoor

| Test Case | Environment | Audio Clarity | Timing | Useful? |
|-----------|-------------|---------------|--------|---------|
| Obstacle announcement | Indoor quiet | [ ] Clear [ ] Muffled | ___s delay | [ ] Y [ ] N |
| Direction cues | Indoor quiet | [ ] Accurate [ ] Confusing | ___s delay | [ ] Y [ ] N |
| Distance reporting | Indoor quiet | [ ] Accurate [ ] Off by >1m | ___s delay | [ ] Y [ ] N |
| Urgent warnings | Indoor quiet | [ ] Distinct [ ] Missed | ___s delay | [ ] Y [ ] N |
| Same tests | Outdoor noisy | [ ] Clear [ ] Muffled | ___s delay | [ ] Y [ ] N |

**Audio Settings to Test**:
- [ ] Verbose mode (all detections)
- [ ] Concise mode (critical only)
- [ ] Urgent mode (immediate dangers)
- [ ] Spatial audio positioning

### 2.4 Navigation Integration

**Test Route**: 500m outdoor walk with varied obstacles

| Checkpoint | GPS Accuracy | Obstacle Warnings | Route Following | Issues |
|------------|--------------|-------------------|-----------------|--------|
| Start | ___m | [ ] Y [ ] N | [ ] On track | |
| 100m | ___m | [ ] Y [ ] N | [ ] On track | |
| 200m | ___m | [ ] Y [ ] N | [ ] On track | |
| 300m | ___m | [ ] Y [ ] N | [ ] On track | |
| 400m | ___m | [ ] Y [ ] N | [ ] On track | |
| End | ___m | [ ] Y [ ] N | [ ] On track | |

**Navigation Metrics**:
- Route deviation: ______ meters
- Obstacle avoidance success rate: ______%
- False turn alerts: ______

---

## Phase 3: Performance Testing (1-2 hours)

### 3.1 Real-Time Processing Performance

**Duration**: 5-minute continuous session

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Average FPS | 25-30 | _____ | [ ] |
| Frame processing latency | <50ms | _____ms | [ ] |
| Memory usage | <300MB | _____MB | [ ] |
| CPU usage | <60% | _____% | [ ] |
| GPU usage | <70% | _____% | [ ] |

**Test Procedure**:
1. Launch app
2. Enable all features (camera, LiDAR, audio)
3. Run for 5 minutes while walking
4. Check Performance HUD for metrics
5. Screenshot performance stats

### 3.2 Battery Life Testing

**Test Duration**: 1 hour continuous use

| Time | Battery % | Screen Brightness | Notes |
|------|-----------|-------------------|-------|
| 0:00 | 100% | 50% | Start |
| 0:15 | ___% | 50% | |
| 0:30 | ___% | 50% | |
| 0:45 | ___% | 50% | |
| 1:00 | ___% | 50% | End |

**Battery Drain Rate**: ______%/hour

**Thermal Performance**:
- Device temperature at start: ______ (warm/hot/normal)
- Device temperature at 30min: ______
- Device temperature at 1hr: ______
- Thermal throttling observed: [ ] Yes [ ] No

### 3.3 Stress Testing

| Test Scenario | Duration | Crashes | Performance Degradation | Pass/Fail |
|---------------|----------|---------|-------------------------|-----------|
| Rapid environment changes | 5 min | _____ | [ ] Y [ ] N | [ ] |
| Low light conditions | 5 min | _____ | [ ] Y [ ] N | [ ] |
| Bright sunlight | 5 min | _____ | [ ] Y [ ] N | [ ] |
| Crowded area (many objects) | 5 min | _____ | [ ] Y [ ] N | [ ] |
| Fast movement/running | 5 min | _____ | [ ] Y [ ] N | [ ] |

---

## Phase 4: Accessibility Validation (1-2 hours)

### 4.1 VoiceOver Integration

**Tester**: Ideally someone familiar with VoiceOver

| Feature | VoiceOver Accessible | Gestures Work | Feedback Clear | Issues |
|---------|---------------------|---------------|----------------|--------|
| Main navigation | [ ] Y [ ] N | [ ] Y [ ] N | [ ] Y [ ] N | |
| Settings menu | [ ] Y [ ] N | [ ] Y [ ] N | [ ] Y [ ] N | |
| Obstacle alerts | [ ] Y [ ] N | [ ] Y [ ] N | [ ] Y [ ] N | |
| Voice commands | [ ] Y [ ] N | [ ] Y [ ] N | [ ] Y [ ] N | |

### 4.2 Real-World Accessibility Scenarios

| Scenario | Success | Issues Encountered | Suggestions |
|----------|---------|-------------------|-------------|
| Navigate indoor hallway | [ ] Y [ ] N | | |
| Cross street intersection | [ ] Y [ ] N | | |
| Avoid stationary obstacles | [ ] Y [ ] N | | |
| Detect approaching people | [ ] Y [ ] N | | |
| Find entrance/exit | [ ] Y [ ] N | | |

### 4.3 User Experience Feedback

**Audio Feedback Quality** (1-5 scale):
- Clarity: _____
- Timeliness: _____
- Usefulness: _____
- Not overwhelming: _____

**Overall Usability** (1-5 scale):
- Easy to learn: _____
- Confident using: _____
- Would recommend: _____

**Open Feedback**:
```
What worked well:


What needs improvement:


Feature requests:


```

---

## Phase 5: Edge Cases & Error Handling (1 hour)

### 5.1 Error Conditions

| Test Case | Trigger | App Response | Recovery | Pass/Fail |
|-----------|---------|--------------|----------|-----------|
| No LiDAR data | Cover depth sensor | [ ] Graceful error | [ ] Y [ ] N | [ ] |
| Camera permission denied | Settings → Deny | [ ] Clear message | [ ] Y [ ] N | [ ] |
| Location disabled | Settings → Disable | [ ] Works offline | [ ] Y [ ] N | [ ] |
| Low memory | Run memory-intensive apps | [ ] No crash | [ ] Y [ ] N | [ ] |
| Background mode | Switch apps | [ ] Resumes correctly | [ ] Y [ ] N | [ ] |

### 5.2 Environmental Edge Cases

| Condition | Detection Quality | Audio Clarity | Navigation Accuracy |
|-----------|-------------------|---------------|---------------------|
| Heavy rain | [ ] Good [ ] Degraded [ ] Failed | [ ] Clear [ ] Muffled | [ ] Good [ ] Poor |
| Fog | [ ] Good [ ] Degraded [ ] Failed | [ ] Clear [ ] Muffled | [ ] Good [ ] Poor |
| Night (dark) | [ ] Good [ ] Degraded [ ] Failed | [ ] Clear [ ] Muffled | [ ] Good [ ] Poor |
| Bright sun | [ ] Good [ ] Degraded [ ] Failed | [ ] Clear [ ] Muffled | [ ] Good [ ] Poor |
| Crowded area | [ ] Good [ ] Degraded [ ] Failed | [ ] Clear [ ] Muffled | [ ] Good [ ] Poor |

---

## Phase 6: Bug Reporting & Documentation

### 6.1 Bugs Discovered

| Bug ID | Severity | Description | Steps to Reproduce | Status |
|--------|----------|-------------|-------------------|--------|
| 001 | [ ] Critical [ ] High [ ] Medium [ ] Low | | | [ ] Open [ ] Fixed |
| 002 | [ ] Critical [ ] High [ ] Medium [ ] Low | | | [ ] Open [ ] Fixed |
| 003 | [ ] Critical [ ] High [ ] Medium [ ] Low | | | [ ] Open [ ] Fixed |

### 6.2 Performance Issues

| Issue | Frequency | Impact | Workaround | Priority |
|-------|-----------|--------|------------|----------|
| | | | | |

### 6.3 Enhancement Suggestions

| Feature | Rationale | Effort Estimate | Priority |
|---------|-----------|-----------------|----------|
| | | | |

---

## Testing Checklist Summary

### Critical Path (Must Pass)
- [ ] App launches on device without crashes
- [ ] LiDAR sensor initializes and provides depth data
- [ ] YOLOv8 model loads and detects objects
- [ ] Audio feedback works and is comprehensible
- [ ] Basic navigation functions (GPS tracking)
- [ ] No crashes during 30-minute continuous use
- [ ] Battery drain < 40%/hour
- [ ] Memory usage < 400MB

### High Priority (Should Pass)
- [ ] Detection accuracy >75% for common objects
- [ ] FPS >20 sustained
- [ ] Latency <75ms
- [ ] VoiceOver compatibility
- [ ] Graceful error handling
- [ ] Thermal management (no overheating)

### Nice to Have (Good to Pass)
- [ ] Detection accuracy >85%
- [ ] FPS >25 sustained
- [ ] Latency <50ms
- [ ] Battery drain <30%/hour
- [ ] All 80 YOLO classes detected accurately

---

## Post-Testing Report

**Date Tested**: _______________
**Device Model**: _______________
**iOS Version**: _______________
**App Version**: _______________

**Overall Assessment**: [ ] Production Ready [ ] Needs Minor Fixes [ ] Needs Major Work

**Top 3 Strengths**:
1.
2.
3.

**Top 3 Issues**:
1.
2.
3.

**Recommendation**:
```
[ ] Ready for beta release
[ ] Ready for internal testing expansion
[ ] Needs additional development
[ ] Requires design changes
```

**Next Steps**:
1.
2.
3.

---

## Quick Start: 30-Minute Smoke Test

If you have limited time, run this abbreviated test:

1. **Setup** (5 min): Deploy to device, grant permissions
2. **Basic Function** (10 min):
   - Launch app, verify camera works
   - Detect 5 different object types
   - Test audio feedback
3. **Performance** (10 min):
   - Check FPS (target: >20)
   - Monitor memory (<300MB)
   - Walk for 5 minutes continuously
4. **Edge Cases** (5 min):
   - Cover LiDAR sensor (verify error handling)
   - Test in low light
   - Test in bright light

**Pass Criteria**: No crashes, basic detection works, audio is clear

---

## Resources

- [Apple LiDAR Best Practices](https://developer.apple.com/documentation/arkit/arkit_in_ios/environmental_analysis_with_arkit)
- [iOS Accessibility Testing Guide](https://developer.apple.com/accessibility/ios/)
- [Xcode Device Testing](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device)

---

**Document Version**: 1.0
**Last Updated**: November 2024
**Contact**: NaviGPT Development Team
