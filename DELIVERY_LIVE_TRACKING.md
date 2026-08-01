# Live GPS Delivery Tracking System

## Overview

This document describes the end-to-end Live GPS Delivery Tracking System for Floraprise, enabling real-time driver location tracking, dispatcher live maps, customer live tracking, and delivery proof capture.

## Architecture

### Components

1. **Backend (ASP.NET Core)**
   - `DriverLocationController` - GPS location upload and retrieval APIs
   - `DeliveryJourneyController` - Journey state management (accept, start, en route, arrived, complete)
   - `DeliveryTrackingHub` - SignalR hub for real-time updates
   - `DriverJourneyService` - Business logic for location handling
   - `ETAUpdateService` - ETA calculation with real-time GPS updates
   - `DeliveryNotificationService` - Customer and florist notifications
   - `DeliveryRateLimitMiddleware` - Rate limiting for location uploads

2. **Database**
   - `DriverLocation` - GPS location history with indexes
   - `DeliverySettings` - Company-specific tracking configuration
   - `DeliveryProof` - Photo, signature, OTP, GPS coordinates
   - `DriverAnalytics` - Performance metrics

3. **Mobile App (Flutter)**
   - `GPSTrackingService` - GPS location capture and upload
   - `DriverJourneyScreen` - Driver journey UI with action buttons
   - `LocationForegroundService` - Android foreground service for background tracking
   - Offline queue for location uploads when no internet

4. **Frontend (React + TypeScript)**
   - `DeliveryLiveMap` - Dispatcher live map with Google Maps
   - `PublicTrackingPage` - Customer live tracking page

### Data Flow

```
Mobile App (GPS) → DriverLocationController → Database → SignalR → Frontend
Mobile App (Actions) → DeliveryJourneyController → Database → SignalR → Frontend
```

## API Endpoints

### Location Upload

**POST /api/delivery/location**
- Upload single GPS location
- Authenticated (driver only)
- Validates driver assignment and delivery status
- Triggers ETA recalculation
- Broadcasts via SignalR

**POST /api/delivery/location/batch**
- Upload multiple GPS locations (offline sync)
- Authenticated (driver only)
- Rate limited: 60 requests/minute, 1000/hour

### Journey Management

**POST /api/delivery/journey/accept**
- Driver accepts delivery assignment

**POST /api/delivery/journey/start**
- Start journey (GPS tracking begins)

**POST /api/delivery/journey/enroute**
- Mark as out for delivery

**POST /api/delivery/journey/arrived**
- Mark as arrived nearby (within geofence)

**POST /api/delivery/journey/complete**
- Complete delivery with proof (photo, signature, OTP, GPS)

**POST /api/delivery/journey/failed**
- Mark delivery as failed

### Live Tracking

**GET /api/delivery/{deliveryId}/live**
- Get live tracking data (anonymous)
- Returns current location, ETA, driver info

**GET /api/delivery/driver/{driverId}/location**
- Get driver's latest location (admin/manager only)

## GPS Tracking Lifecycle

### 1. Permission Request
- App requests `ACCESS_FINE_LOCATION` and `ACCESS_BACKGROUND_LOCATION`
- Shows user-friendly explanation
- Handles permission denial gracefully

### 2. Start Tracking
- Called when driver starts journey
- Initializes high-accuracy GPS stream
- Starts Android foreground service
- Begins 15-second upload interval

### 3. Location Capture
- GPS stream updates every 5 seconds
- Filters by minimum distance (25m)
- Captures: latitude, longitude, accuracy, speed, heading, altitude, battery

### 4. Upload Strategy
- Upload every 15 seconds OR on significant distance change (25m)
- Check connectivity before upload
- Queue offline if no internet
- Batch upload queued locations when connection restored

### 5. Stop Tracking
- Called on delivery completion
- Cancels GPS stream
- Stops foreground service
- Clears offline queue

## Battery Optimization

### Settings
- Enable/disable battery optimization (default: enabled)
- Low battery threshold: 20%
- Adjust GPS accuracy based on battery level

### Strategies
- Reduce upload frequency when battery < 20%
- Use balanced accuracy mode when battery low
- Pause tracking when battery critically low
- Show battery status in app

## Failure Handling

### GPS Failures
- Permission denied: Show user-friendly message, guide to settings
- GPS disabled: Prompt user to enable location services
- Timeout: Retry with exponential backoff
- Low accuracy: Continue but flag for review

### Network Failures
- Offline: Queue locations locally
- Upload failure: Keep in queue, retry on next upload
- Batch upload failure: Split into smaller batches
- Server error: Log and continue (don't block app)

### SignalR Failures
- Connection lost: Fall back to 15-second polling
- Reconnect: Automatic with exponential backoff
- Broadcast failure: Log error, continue processing

## ETA Calculation

### Algorithm
- Uses Haversine formula for distance calculation
- Factors in current speed from GPS
- Applies traffic factor (1.2x by default)
- Recalculates on every location upload

### Formula
```
distance_km = haversine(current_lat, current_lng, dest_lat, dest_lng)
speed_kmh = current_speed_mps * 3.6
time_hours = distance_km / speed_kmh
eta_minutes = time_hours * 60 * traffic_factor
```

## Real-Time Updates

### SignalR Events

**LocationUpdated**
- Broadcasted on every location upload
- Sent to delivery group and dispatchers
- Payload: latitude, longitude, accuracy, speed, heading, timestamp

**StatusChanged**
- Broadcasted on journey state changes
- Sent to delivery group and dispatchers
- Payload: deliveryId, status, additionalData

**ETAUpdated**
- Broadcasted when ETA recalculated
- Sent to delivery group
- Payload: deliveryId, eta, remainingDistance

### Fallback Polling
- 15-second interval if SignalR unavailable
- Graceful degradation
- Automatic reconnection attempt

## Delivery Proof

### Components
- **Photo**: Required by default
- **Signature**: Optional (digital signature capture)
- **OTP**: Optional (4-digit code sent to customer)
- **GPS Coordinates**: Captured at completion
- **Timestamp**: Auto-recorded

### Verification
- OTP validation before completion (if required)
- GPS coordinates within geofence check
- Photo upload mandatory
- Notes optional

## Security

### Authentication
- All location upload endpoints require authentication
- Drivers can only upload their own locations
- Role-based access for admin endpoints

### Authorization
- Drivers update only their assigned deliveries
- Customers access only their own tracking
- Admins access all driver locations

### Rate Limiting
- 60 requests/minute per client
- 1000 requests/hour per client
- Based on user ID or IP address
- Returns 429 Too Many Requests on limit

### Data Privacy
- Customer can choose to disable tracking
- Driver phone number hidden by default
- Driver photo shown based on settings
- Location data retained for 30 days (configurable)

## Notification Types

### Customer Notifications
- Delivery accepted
- Picked up
- Out for delivery
- Arrived nearby
- Delivered
- Failed
- Delayed

### Florist Notifications
- All status changes
- Delivery failures
- Delay alerts

### Channels
- SMS (Twilio integration - TODO)
- Email (SendGrid integration - TODO)
- In-app (SignalR)

## Settings Configuration

### GPS Tracking
- Upload interval: 15 seconds (default)
- Minimum distance: 25 meters
- Location retention: 30 days

### Geofence
- Arrived nearby radius: 200 meters
- "I'm Outside" radius: 150 meters

### Delay
- Threshold: 15 minutes
- Auto-notify: enabled

### Proof Requirements
- Photo required: true
- Signature required: false
- OTP required: false
- OTP length: 4 digits

### Privacy
- Show driver phone: false
- Show driver photo: true
- Allow customer tracking: true

## Analytics

### Metrics Tracked
- Total deliveries per day
- Completed/failed/delayed counts
- Average delivery time
- Total distance traveled
- GPS accuracy averages
- Battery level averages
- Low battery alerts
- Tracking duration

### Reporting
- Daily aggregation
- Driver performance comparison
- Route efficiency analysis
- Battery usage patterns

## "I'm Outside" Feature

### Trigger
- Driver within 150m of destination
- Automatic detection via GPS
- Manual button available

### Actions
- Send notification to customer
- Update delivery status to "ArrivedNearby"
- Trigger customer app alert

### Configuration
- Radius: 150m (configurable)
- Notification template: customizable
- Opt-out available for customers

## UAT Scenarios

### 1. Driver Login and Journey Start
- Driver logs in to mobile app
- Accepts delivery assignment
- Starts journey
- GPS tracking begins
- Location uploads verified

### 2. Live Map Updates
- Dispatcher opens live map
- Driver location updates every 15 seconds
- Route line displays correctly
- ETA recalculates dynamically
- Status changes reflected

### 3. Customer Tracking
- Customer opens tracking link
- Sees driver location on map
- ETA updates in real-time
- Driver info displayed (based on settings)
- Proof shown after delivery

### 4. Offline Queue
- Driver loses internet connection
- Locations queued locally
- Connection restored
- Batch upload succeeds
- No data loss

### 5. Battery Optimization
- Battery drops below 20%
- Upload frequency reduced
- GPS accuracy adjusted
- Low battery alert logged
- Tracking continues

### 6. Delivery Completion
- Driver marks arrived nearby
- "I'm Outside" notification sent
- Customer receives alert
- Driver completes with photo
- OTP validated (if required)
- Delivery status updated
- Customer notified of completion

## Deployment Checklist

### Backend
- [ ] Database migration applied (AddDriverLocationTracking)
- [ ] SignalR hub configured
- [ ] Rate limiting middleware enabled
- [ ] Notification services integrated (SMS/Email)
- [ ] Google Maps API key configured

### Mobile
- [ ] Location permissions added to AndroidManifest
- [ ] Foreground service configured
- [ ] Background location enabled
- [ ] Offline queue tested
- [ ] Battery optimization tested

### Frontend
- [ ] Google Maps API key configured
- [ ] SignalR client configured
- [ ] Live map tested
- [ ] Customer tracking tested
- [ ] Responsive design verified

## Troubleshooting

### GPS Not Updating
- Check location permissions
- Verify GPS is enabled
- Check internet connectivity
- Review rate limit status
- Check battery optimization settings

### SignalR Not Connecting
- Verify hub URL configuration
- Check authentication token
- Review browser console for errors
- Test fallback polling

### ETA Not Accurate
- Verify destination coordinates
- Check GPS accuracy
- Review traffic factor setting
- Verify speed data from GPS

### Battery Draining Fast
- Reduce upload interval
- Enable battery optimization
- Check GPS accuracy setting
- Review tracking duration

## Future Enhancements

- Machine learning for ETA prediction
- Route optimization integration
- Traffic API integration
- Voice navigation for drivers
- Customer chat with driver
- Multi-stop route planning
- Weather-based ETA adjustment
- Predictive failure alerts
