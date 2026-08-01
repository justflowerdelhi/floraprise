# UAT Test Plan - Live GPS Delivery Tracking

## Overview

This document outlines the 6 User Acceptance Testing (UAT) scenarios for the Live GPS Delivery Tracking System. Each scenario includes test steps, expected results, and acceptance criteria.

## Prerequisites

- Backend API running with database migration applied
- Mobile app installed on Android device with location permissions
- Frontend web application accessible
- Test driver account created
- Test delivery assigned to driver
- Google Maps API key configured
- SignalR hub configured

---

## Scenario 1: Driver Login and Journey Start

### Objective
Verify driver can log in, accept delivery, and start GPS tracking.

### Test Steps
1. Open mobile app
2. Enter driver credentials (username/password)
3. Tap "Login"
4. Navigate to "My Deliveries"
5. Locate assigned delivery
6. Tap "Accept Delivery"
7. Tap "Start Journey"
8. Verify GPS tracking indicator appears
9. Wait 30 seconds
10. Check backend database for location records

### Expected Results
- Login successful
- Delivery list displays assigned delivery
- "Accept" button changes to "Start Journey"
- GPS tracking indicator shows "Tracking Active"
- Location records appear in `DriverLocations` table
- Records include: latitude, longitude, accuracy, speed, heading, battery
- Upload interval ~15 seconds

### Acceptance Criteria
- [ ] Driver can successfully log in
- [ ] Assigned delivery visible in list
- [ ] Accept/Start journey buttons work
- [ ] GPS tracking starts
- [ ] Location data uploads to backend
- [ ] Data includes all required fields

### Troubleshooting
- If login fails: Check credentials, verify API connectivity
- If delivery not visible: Verify assignment in database
- If GPS not tracking: Check location permissions, enable GPS
- If no location uploads: Check internet connectivity, review rate limits

---

## Scenario 2: Live Map Updates

### Objective
Verify dispatcher live map shows real-time driver location and status updates.

### Test Steps
1. Log in as dispatcher/admin
2. Navigate to "Delivery Live Map"
3. Verify map loads with Google Maps
4. Locate driver marker on map
5. Wait 30 seconds
6. Observe marker movement
7. Click driver marker
8. Verify info window displays driver details
9. Check status legend colors
10. Verify ETA display updates

### Expected Results
- Map loads without errors
- Driver marker displays with correct color (Blue for Moving)
- Marker updates position every 15 seconds
- Info window shows: driver name, status, current delivery, ETA, speed
- Status legend shows all 6 status colors
- ETA recalculates dynamically
- Route line displays from driver to destination

### Acceptance Criteria
- [ ] Map loads successfully
- [ ] Driver marker visible
- [ ] Marker updates in real-time
- [ ] Info window displays correct data
- [ ] Status legend accurate
- [ ] ETA updates dynamically
- [ ] Route line displays

### Troubleshooting
- If map doesn't load: Check Google Maps API key, verify internet
- If marker not visible: Check driver has active location uploads
- If marker not updating: Check SignalR connection, verify rate limits
- If ETA not updating: Verify destination coordinates set

---

## Scenario 3: Customer Tracking

### Objective
Verify customer can track delivery in real-time via public tracking page.

### Test Steps
1. Generate tracking link for test delivery
2. Open tracking link in browser (no authentication)
3. Verify page loads with delivery details
4. Check status display
5. Verify driver info shows (based on settings)
6. Wait 30 seconds
7. Observe map marker movement
8. Check ETA updates
9. Verify timeline displays
10. Test refresh button

### Expected Results
- Page loads without authentication
- Shows: order number, customer name, address, time slot
- Status chip displays current status
- Driver info shows name (phone based on settings)
- Map displays driver marker (blue)
- Destination marker displays (red)
- Route line connects markers
- ETA updates every 15 seconds
- Timeline shows status history
- Refresh button works

### Acceptance Criteria
- [ ] Public tracking page accessible
- [ ] Delivery details display correctly
- [ ] Driver info shows based on settings
- [ ] Map displays with markers
- [ ] ETA updates in real-time
- [ ] Timeline shows history
- [ ] Refresh button functional

### Troubleshooting
- If page doesn't load: Check tracking token, verify API endpoint
- If map doesn't load: Check Google Maps API key
- If driver info hidden: Check privacy settings
- If ETA not updating: Verify location uploads active

---

## Scenario 4: Offline Queue

### Objective
Verify location uploads queue when offline and sync when connection restored.

### Test Steps
1. Start driver journey (GPS tracking active)
2. Disable device internet (airplane mode)
3. Wait 60 seconds (multiple location captures)
4. Re-enable internet
5. Wait 30 seconds
6. Check backend database
7. Verify all queued locations uploaded
8. Check timestamps
9. Verify no data loss

### Expected Results
- GPS continues tracking while offline
- Locations queued locally
- Queue count increases while offline
- On reconnection, batch upload triggers
- All queued locations upload to backend
- Timestamps reflect actual capture time
- No duplicate or missing records
- Order preserved

### Acceptance Criteria
- [ ] GPS continues offline
- [ ] Locations queue locally
- [ ] Batch upload on reconnection
- [ ] All locations uploaded
- [ ] Timestamps accurate
- [ ] No data loss
- [ ] Order preserved

### Troubleshooting
- If GPS stops offline: Check foreground service, verify permissions
- If queue not working: Check local storage, review queue logic
- If batch upload fails: Check API endpoint, verify rate limits
- If timestamps wrong: Check time synchronization

---

## Scenario 5: Battery Optimization

### Objective
Verify battery optimization features work correctly.

### Test Steps
1. Start driver journey with battery > 50%
2. Monitor upload interval (should be 15s)
3. Drain battery to < 20% (use device settings or wait)
4. Observe upload interval change
5. Check GPS accuracy mode
6. Verify low battery alert logged
7. Continue tracking for 5 minutes
8. Verify tracking continues despite low battery

### Expected Results
- Normal upload interval: 15 seconds
- High GPS accuracy when battery > 20%
- When battery < 20%:
  - Upload interval increases (e.g., 30s)
  - GPS accuracy reduces to balanced
  - Low battery alert logged in analytics
- Tracking continues uninterrupted
- App doesn't crash
- Location uploads continue (slower)

### Acceptance Criteria
- [ ] Normal tracking at high battery
- [ ] Upload interval adjusts at low battery
- [ ] GPS accuracy reduces at low battery
- [ ] Low battery alert logged
- [ ] Tracking continues
- [ ] App remains stable
- [ ] No crashes

### Troubleshooting
- If battery threshold not working: Check settings, verify battery reading
- If upload interval doesn't change: Review optimization logic
- If GPS accuracy doesn't change: Check geolocator settings
- If app crashes: Review memory usage, check for leaks

---

## Scenario 6: Delivery Completion

### Objective
Verify end-to-end delivery completion with proof capture and notifications.

### Test Steps
1. Start driver journey
2. Drive to near destination (within 150m)
3. Wait for "I'm Outside" notification
4. Verify customer receives notification
5. Tap "Complete Delivery"
6. Capture photo proof
7. Enter recipient name
8. Enter notes (optional)
9. Verify GPS coordinates captured
10. Tap "Submit"
11. Verify delivery status changes to "Delivered"
12. Verify customer receives completion notification
13. Check delivery proof in database
14. Verify proof includes: photo, recipient, notes, GPS, timestamp

### Expected Results
- At 150m: "I'm Outside" notification triggers
- Customer receives SMS/Email (if configured)
- Delivery status changes to "ArrivedNearby"
- "Complete Delivery" screen opens
- Camera opens for photo capture
- Photo uploads successfully
- GPS coordinates auto-captured
- Status changes to "Delivered"
- Customer receives completion notification
- Proof stored in `DeliveryProof` table
- Proof includes all required fields

### Acceptance Criteria
- [ ] "I'm Outside" notification triggers at 150m
- [ ] Customer receives notification
- [ ] Status changes to "ArrivedNearby"
- [ ] Photo capture works
- [ ] Photo uploads successfully
- [ ] GPS coordinates captured
- [ ] Status changes to "Delivered"
- [ ] Customer receives completion notification
- [ ] Proof stored correctly
- [ ] Proof includes all fields

### Troubleshooting
- If "I'm Outside" not triggering: Check geofence radius, verify GPS accuracy
- If notification not sent: Check notification service, verify SMS/Email config
- If photo capture fails: Check camera permissions, verify storage
- If GPS not captured: Check location permissions, verify GPS active
- If status not updating: Check API endpoint, verify database connection

---

## Test Environment Setup

### Backend
```bash
# Apply database migration
dotnet ef database update

# Verify SignalR hub configured
# Check appsettings.json for Google Maps API key
# Verify rate limiting middleware enabled
```

### Mobile
```bash
# Install app on test device
# Grant location permissions (foreground and background)
# Enable GPS
# Disable battery optimization for app
```

### Frontend
```bash
# Build and run web app
# Configure Google Maps API key in .env
# Verify SignalR client configured
```

## Test Data Preparation

1. Create test driver account
2. Create test customer account
3. Create test delivery with:
   - Assigned to test driver
   - Valid destination coordinates
   - Customer phone/email for notifications
4. Generate tracking token for customer

## Test Execution Checklist

### Before Testing
- [ ] Backend API running
- [ ] Database migration applied
- [ ] Mobile app installed
- [ ] Location permissions granted
- [ ] GPS enabled
- [ ] Test data prepared
- [ ] Google Maps API key configured
- [ ] SignalR hub accessible

### During Testing
- [ ] Document any deviations
- [ ] Capture screenshots of errors
- [ ] Log timestamps for verification
- [ ] Record battery levels
- [ ] Monitor rate limit status

### After Testing
- [ ] Clean up test data
- [ ] Review database for orphaned records
- [ ] Clear offline queues
- [ ] Reset driver status
- [ ] Document test results

## Success Criteria

All 6 scenarios must pass with at least 90% of acceptance criteria met. Any failures must be documented with root cause and resolution plan.

## Sign-off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| QA Tester | | | |
| Product Owner | | | |
| Developer | | | |

## Notes

Add any additional observations, issues, or recommendations discovered during testing.
