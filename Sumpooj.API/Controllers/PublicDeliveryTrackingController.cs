using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Npgsql;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.DeliveryTracking;
using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[Route("api/public/tracking")]
[ApiController]
public class PublicDeliveryTrackingController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly IDeliveryTrackingService _trackingService;
    private readonly DriverJourneyService _journeyService;
    private readonly IDeliveryRepository _deliveryRepository;
    private readonly IConfiguration _configuration;

    public PublicDeliveryTrackingController(
        SumpoojDbContext db,
        IDeliveryTrackingService trackingService,
        DriverJourneyService journeyService,
        IDeliveryRepository deliveryRepository,
        IConfiguration configuration)
    {
        _db = db;
        _trackingService = trackingService;
        _journeyService = journeyService;
        _deliveryRepository = deliveryRepository;
        _configuration = configuration;
    }

    private sealed record TokenDeliveryContext(
        Delivery Delivery,
        Order? Order,
        Customer? Customer,
        DeliverySettings? Settings,
        string ProductSummary,
        string Occasion);

    private async Task<TokenDeliveryContext?> FindByTokenAsync(string token)
    {
        var delivery = await _db.Deliveries.FirstOrDefaultAsync(d => d.TrackingToken == token);
        if (delivery == null)
            return null;

        var order = await _db.Orders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == delivery.SalesOrderId);

        Customer? customer = null;
        if (order != null)
        {
            customer = await _db.Customers.FirstOrDefaultAsync(c => c.Id == order.CustomerId);
        }

        var settings = await TryGetDeliverySettingsAsync(delivery.CompanyId);

        return new TokenDeliveryContext(
            delivery,
            order,
            customer,
            settings,
            BuildProductSummary(order),
            ExtractOccasion(order));
    }

    private Task<DeliverySettings?> TryGetDeliverySettingsAsync(Guid companyId)
    {
        return _db.DeliverySettings.FirstOrDefaultAsync(s => s.CompanyId == companyId);
    }

    private static string NormalizePhone(string value)
    {
        return new string(value.Where(char.IsDigit).ToArray());
    }

    private string ResolvePublicBaseUrl()
    {
        var configured = _configuration["PublicBaseUrl"];
        if (!string.IsNullOrWhiteSpace(configured))
            return configured.TrimEnd('/');

        return $"{Request.Scheme}://{Request.Host.Value}".TrimEnd('/');
    }

    private static string BuildProductSummary(Order? order)
    {
        if (order == null || order.Items.Count == 0)
            return "Product details not available";

        var lines = order.Items
            .Take(3)
            .Select(i => $"{i.Quantity} x {i.ProductName}")
            .ToList();

        if (order.Items.Count > 3)
            lines.Add($"+{order.Items.Count - 3} more item(s)");

        return string.Join(", ", lines);
    }

    private static string ExtractOccasion(Order? order)
    {
        var notes = order?.InternalNotes;
        if (string.IsNullOrWhiteSpace(notes))
            return string.Empty;

        foreach (var line in notes.Split('\n'))
        {
            var trimmed = line.Trim();
            if (trimmed.StartsWith("Occasion:", StringComparison.OrdinalIgnoreCase))
            {
                return trimmed["Occasion:".Length..].Trim();
            }
        }

        return string.Empty;
    }

    /// <summary>
    /// Get public delivery tracking by secure token (Customer view)
    /// No authentication required
    /// </summary>
    [HttpGet("customer/{token}")]
    public async Task<IActionResult> GetPublicTracking(string token)
    {
        try
        {
            var delivery = await FindByTokenAsync(token);

            if (delivery == null)
            {
                return NotFound(new { error = "Invalid tracking token" });
            }

            var deliveryEntity = delivery.Delivery;
            var driver = deliveryEntity.DeliveryPersonId.HasValue
                ? await _db.Staff
                    .AsNoTracking()
                    .Where(s => s.Id == deliveryEntity.DeliveryPersonId.Value)
                    .Select(s => new { s.Name, s.Phone })
                    .FirstOrDefaultAsync()
                : null;
            var lastLocation = await _db.DriverLocations
                .Where(l => l.DeliveryId == deliveryEntity.Id)
                .OrderByDescending(l => l.RecordedAt)
                .Select(l => new
                {
                    lat = l.Latitude,
                    lng = l.Longitude,
                    recordedAt = l.RecordedAt
                })
                .FirstOrDefaultAsync();
            var route = await _db.DriverLocations
                .Where(l => l.DeliveryId == deliveryEntity.Id)
                .OrderBy(l => l.RecordedAt)
                .Take(200)
                .Select(l => new
                {
                    lat = l.Latitude,
                    lng = l.Longitude,
                    speed = l.Speed,
                    heading = l.Heading,
                    recordedAt = l.RecordedAt
                })
                .ToListAsync();
            var timeline = await _db.DeliveryTimelines
                .Where(t => t.DeliveryId == deliveryEntity.Id)
                .OrderBy(t => t.RecordedAt)
                .Take(100)
                .Select(t => new
                {
                    status = t.Status,
                    note = t.Note,
                    timestamp = t.RecordedAt,
                    changedBy = t.ChangedByUserName
                })
                .ToListAsync();
            var proof = await _db.DeliveryProofs
                .Where(p => p.DeliveryId == deliveryEntity.Id)
                .OrderByDescending(p => p.RecordedAt)
                .Select(p => new
                {
                    photoUrl = p.PhotoUrl,
                    recipientName = p.RecipientName,
                    note = p.Note,
                    timestamp = p.RecordedAt
                })
                .FirstOrDefaultAsync();

            // Check if delivery is completed (token expires after delivery)
            if (deliveryEntity.Status == DeliveryStatus.Delivered)
            {
                // Allow viewing completed deliveries for 24 hours
                if (deliveryEntity.UpdatedAtUtc.HasValue && 
                    (DateTime.UtcNow - deliveryEntity.UpdatedAtUtc.Value).TotalHours > 24)
                {
                    return NotFound(new { error = "Tracking link has expired" });
                }
            }

            // Return public-safe data (exclude sensitive info)
            return Ok(new
            {
                orderId = deliveryEntity.SalesOrderId,
                orderNumber = delivery.Order?.OrderNumber ?? deliveryEntity.SalesOrderId.ToString(),
                customerName = delivery.Customer?.Name ?? "Customer",
                deliveryAddress = deliveryEntity.DeliveryAddress,
                timeSlot = deliveryEntity.TimeSlot,
                status = deliveryEntity.Status.ToString(),
                eta = deliveryEntity.DeliveryDate,
                tracking = new
                {
                    driverName = driver?.Name,
                    driverPhone = driver?.Phone,
                    lastLocation = lastLocation,
                    route = route,
                    timeline = timeline,
                    proof = proof
                }
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get driver start link details by secure token (Driver view)
    /// No authentication required - driver validates via token
    /// </summary>
    [HttpGet("driver/{token}")]
    public async Task<IActionResult> GetDriverStartLink(string token)
    {
        try
        {
            var delivery = await FindByTokenAsync(token);

            if (delivery == null)
            {
                return NotFound(new { error = "Invalid tracking token" });
            }

            var deliveryEntity = delivery.Delivery;

            // Check if delivery is already completed or cancelled
            if (deliveryEntity.Status == DeliveryStatus.Delivered || 
                deliveryEntity.Status == DeliveryStatus.Cancelled ||
                deliveryEntity.Status == DeliveryStatus.SettlementCompleted)
            {
                return BadRequest(new { error = "Delivery is already completed or cancelled" });
            }

            // Return driver-safe data
            return Ok(new
            {
                deliveryId = deliveryEntity.Id,
                orderId = deliveryEntity.SalesOrderId,
                orderNumber = delivery.Order?.OrderNumber ?? deliveryEntity.SalesOrderId.ToString(),
                customerName = delivery.Customer?.Name ?? "Customer",
                recipientName = string.IsNullOrWhiteSpace(delivery.Order?.RecipientName)
                    ? (delivery.Customer?.Name ?? "Recipient")
                    : delivery.Order!.RecipientName,
                deliveryAddress = deliveryEntity.DeliveryAddress,
                destinationLatitude = deliveryEntity.DeliveryAddressLatitude,
                destinationLongitude = deliveryEntity.DeliveryAddressLongitude,
                customerPhone = deliveryEntity.CustomerPhone,
                timeSlot = deliveryEntity.TimeSlot,
                status = deliveryEntity.Status.ToString(),
                trackingToken = deliveryEntity.TrackingToken,
                mapsUrl = BuildMapsSearchUrl(deliveryEntity.DeliveryAddress),
                occasion = delivery.Occasion,
                productSummary = delivery.ProductSummary,
                requirePhotoProof = delivery.Settings?.RequirePhotoProof ?? false,
                requireOtp = delivery.Settings?.RequireOTP ?? false,
                requireSignature = delivery.Settings?.RequireSignature ?? false,
                locationUploadIntervalSeconds = delivery.Settings?.LocationUploadIntervalSeconds ?? 20
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

        [HttpGet("/delivery/{token}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetDeliveryByToken(string token)
        {
                var delivery = await FindByTokenAsync(token);
                if (delivery == null)
                        return NotFound(new { error = "Invalid tracking token" });

                var item = delivery.Delivery;
                return Ok(new
                {
                        deliveryId = item.Id,
                        orderId = item.SalesOrderId,
                        orderNumber = delivery.Order?.OrderNumber ?? item.SalesOrderId.ToString(),
                        customerName = delivery.Customer?.Name ?? "Customer",
                        recipientName = string.IsNullOrWhiteSpace(delivery.Order?.RecipientName)
                            ? (delivery.Customer?.Name ?? "Recipient")
                            : delivery.Order!.RecipientName,
                        deliveryAddress = item.DeliveryAddress,
                        customerPhone = item.CustomerPhone,
                        timeSlot = item.TimeSlot,
                        status = item.Status.ToString(),
                        trackingToken = item.TrackingToken,
                        destinationLatitude = item.DeliveryAddressLatitude,
                        destinationLongitude = item.DeliveryAddressLongitude,
                        mapsUrl = BuildMapsSearchUrl(item.DeliveryAddress),
                        occasion = delivery.Occasion,
                        productSummary = delivery.ProductSummary,
                        eta = item.DeliveryDate,
                        requirePhotoProof = delivery.Settings?.RequirePhotoProof ?? false,
                        requireOtp = delivery.Settings?.RequireOTP ?? false,
                        requireSignature = delivery.Settings?.RequireSignature ?? false,
                        locationUploadIntervalSeconds = delivery.Settings?.LocationUploadIntervalSeconds ?? 20,
                        startedAtUtc = item.StartedAtUtc,
                        completedAtUtc = item.CompletedAtUtc,
                        lastLocationUtc = item.LastLocationUtc
                });
        }

        [HttpPost("/delivery/{token}/accept")]
        [AllowAnonymous]
        public async Task<IActionResult> AcceptDeliveryByToken(string token)
        {
            var delivery = await _db.Deliveries.FirstOrDefaultAsync(d => d.TrackingToken == token);
            if (delivery == null)
                return NotFound(new { error = "Invalid tracking token" });

            if (delivery.Status is DeliveryStatus.Cancelled or DeliveryStatus.Delivered or DeliveryStatus.SettlementCompleted)
                return BadRequest(new { error = "Delivery is already completed or cancelled" });

            if (delivery.Status == DeliveryStatus.Assigned)
            {
                var driverId = delivery.DeliveryPersonId ?? Guid.NewGuid();
                delivery.MarkAccepted(driverId);
                await _db.SaveChangesAsync();
            }

            return Ok(new { success = true, status = delivery.Status.ToString() });
        }

        [HttpPost("/delivery/{token}/reject")]
        [AllowAnonymous]
        public async Task<IActionResult> RejectDeliveryByToken(string token)
        {
            var delivery = await _db.Deliveries.FirstOrDefaultAsync(d => d.TrackingToken == token);
            if (delivery == null)
                return NotFound(new { error = "Invalid tracking token" });

            if (delivery.Status == DeliveryStatus.Cancelled)
                return Ok(new { success = true, status = delivery.Status.ToString() });

            if (delivery.Status is DeliveryStatus.Delivered or DeliveryStatus.SettlementCompleted)
                return BadRequest(new { error = "Delivered shipments cannot be rejected" });

            if (delivery.Status != DeliveryStatus.Assigned && delivery.Status != DeliveryStatus.Accepted)
                return BadRequest(new { error = "Delivery can be rejected only before trip start" });

            delivery.Cancel();
            await _db.SaveChangesAsync();
            return Ok(new { success = true, status = delivery.Status.ToString() });
        }

        [HttpGet("/delivery/start/{token}")]
        [AllowAnonymous]
        public IActionResult DriverStartLinkAlias(string token)
        {
                return Redirect($"/d/{token}");
        }

        [HttpGet("/d/{token}")]
        [AllowAnonymous]
        public IActionResult DriverPortalPage(string token)
        {
                var safeToken = token.Replace("'", "", StringComparison.Ordinal);
                var html = $@"<!doctype html>
<html lang='en'>
<head>
    <meta charset='utf-8'/>
    <meta name='viewport' content='width=device-width, initial-scale=1'/>
    <title>Floraprise Driver</title>
    <style>
        :root {{ --bg:#f3f5f8; --card:#fff; --ink:#111827; --muted:#6b7280; --line:#e5e7eb; --ok:#047857; --warn:#b91c1c; --btn:#111827; --btn2:#065f46; }}
        * {{ box-sizing:border-box; }}
        body {{ margin:0; font-family:Segoe UI,Arial,sans-serif; background:var(--bg); color:var(--ink); }}
        .wrap {{ max-width:760px; margin:0 auto; padding:16px; }}
        .card {{ background:var(--card); border:1px solid var(--line); border-radius:14px; padding:16px; margin-bottom:12px; }}
        h1 {{ margin:0 0 12px; font-size:24px; }}
        h2 {{ margin:0 0 12px; font-size:18px; }}
        .row {{ display:grid; grid-template-columns:140px 1fr; gap:8px; padding:5px 0; }}
        .k {{ color:var(--muted); }}
        .status {{ display:inline-block; padding:6px 10px; border-radius:999px; background:#eef2ff; font-weight:700; }}
        .btn {{ width:100%; border:none; border-radius:12px; padding:14px; margin-top:8px; color:#fff; font-weight:700; font-size:16px; cursor:pointer; }}
        .btnMain {{ background:var(--btn); }}
        .btnOk {{ background:var(--btn2); }}
        .btnDanger {{ background:#b91c1c; }}
        .btnGhost {{ background:#374151; }}
        .inline {{ display:grid; grid-template-columns:1fr 1fr; gap:10px; }}
        .hint {{ color:var(--muted); margin-top:8px; }}
        .err {{ color:var(--warn); font-weight:600; white-space:pre-wrap; margin-top:8px; }}
        .ok {{ color:var(--ok); font-weight:700; }}
        .hide {{ display:none; }}
        .box {{ border:1px dashed #d1d5db; border-radius:10px; padding:10px; margin-top:8px; }}
        label {{ display:flex; gap:8px; align-items:center; padding:6px 0; }}
        @media (max-width: 640px) {{ .row {{ grid-template-columns:1fr; }} .inline {{ grid-template-columns:1fr; }} }}
    </style>
</head>
<body>
    <div class='wrap'>
        <div class='card'>
            <h1>Floraprise Driver</h1>
            <div id='loading'>Loading delivery...</div>
            <div id='error' class='err hide'></div>
            <div id='summary' class='hide'>
                <div class='row'><div class='k'>Order Number</div><div id='orderNumber'></div></div>
                <div class='row'><div class='k'>Customer Name</div><div id='customerName'></div></div>
                <div class='row'><div class='k'>Recipient Name</div><div id='recipientName'></div></div>
                <div class='row'><div class='k'>Phone</div><div id='phone'></div></div>
                <div class='row'><div class='k'>Address</div><div id='address'></div></div>
                <div class='row'><div class='k'>Delivery Slot</div><div id='slot'></div></div>
                <div class='row'><div class='k'>Occasion</div><div id='occasion'></div></div>
                <div class='row'><div class='k'>Product Summary</div><div id='products'></div></div>
                <div class='row'><div class='k'>Status</div><div><span id='status' class='status'></span></div></div>
                <a id='mapsLink' target='_blank' rel='noreferrer noopener'><button class='btn btnGhost' type='button'>Navigate with Google Maps</button></a>
            </div>
        </div>

        <div id='acceptCard' class='card hide'>
            <h2>Waiting for your action</h2>
            <button id='acceptBtn' class='btn btnOk'>ACCEPT DELIVERY</button>
            <button id='rejectBtn' class='btn btnDanger'>REJECT DELIVERY</button>
            <div id='acceptErr' class='err'></div>
        </div>

        <div id='startCard' class='card hide'>
            <h2>Preparing to Start</h2>
            <div class='hint'>Allow location to begin live delivery tracking.</div>
            <button id='startBtn' class='btn btnMain'>START DELIVERY</button>
            <button id='retryPermissionBtn' class='btn btnGhost hide'>RETRY LOCATION PERMISSION</button>
            <div id='startErr' class='err'></div>
        </div>

        <div id='travelCard' class='card hide'>
            <h2>Out For Delivery</h2>
            <div class='row'><div class='k'>Customer</div><div id='tripCustomer'></div></div>
            <div class='row'><div class='k'>Recipient</div><div id='tripRecipient'></div></div>
            <div class='row'><div class='k'>Phone</div><div id='tripPhone'></div></div>
            <div class='row'><div class='k'>Address</div><div id='tripAddress'></div></div>
            <div class='row'><div class='k'>ETA</div><div id='tripEta'></div></div>
            <div class='row'><div class='k'>GPS Status</div><div id='gpsStatus' class='ok'>GPS Active</div></div>
            <div class='inline'>
                <a id='callLink'><button class='btn btnGhost' type='button'>Call Customer</button></a>
                <a id='navLink' target='_blank' rel='noreferrer noopener'><button class='btn btnGhost' type='button'>Navigate</button></a>
            </div>

            <div id='proofBox' class='box hide'>
                <div><strong>Delivery Successful?</strong></div>
                <label id='photoRow' class='hide'><input id='photoEnabled' type='checkbox'/> Take Photo (URL)</label>
                <input id='photoInput' class='hide' placeholder='Photo URL' />
                <label id='otpRow' class='hide'><input id='otpEnabled' type='checkbox'/> Enter OTP</label>
                <input id='otpInput' class='hide' placeholder='OTP' />
                <label id='sigRow' class='hide'><input id='sigEnabled' type='checkbox'/> Customer Signature</label>
                <input id='sigInput' class='hide' placeholder='Signature value' />
            </div>

            <button id='completeBtn' class='btn btnMain'>COMPLETE DELIVERY</button>
            <div id='completeErr' class='err'></div>
        </div>
    </div>

    <script>
        const token = '{safeToken}';
        const queueKey = 'floraprise:driver:gps:' + token;
        let current = null;
        let watchId = null;
        let lastPush = 0;

        function byId(id) {{ return document.getElementById(id); }}
        function normalizeStatus(v) {{ return (v || '').replace(/[^a-z]/gi, '').toLowerCase(); }}
        function hide(id, flag) {{ byId(id).classList.toggle('hide', !!flag); }}

        async function getJson(url, init) {{
            const res = await fetch(url, init);
            const body = await res.json().catch(() => ({{}}));
            if (!res.ok) throw new Error(body.error || 'Request failed');
            return body;
        }}

        function queuePoint(payload) {{
            const list = JSON.parse(localStorage.getItem(queueKey) || '[]');
            list.push(payload);
            localStorage.setItem(queueKey, JSON.stringify(list));
        }}

        async function flushQueue() {{
            const list = JSON.parse(localStorage.getItem(queueKey) || '[]');
            if (!Array.isArray(list) || list.length === 0) return;
            const remaining = [];
            for (const item of list) {{
                try {{
                    await postLocation(item.latitude, item.longitude, item.recordedAt, false);
                }} catch {{
                    remaining.push(item);
                }}
            }}
            localStorage.setItem(queueKey, JSON.stringify(remaining));
        }}

        function render(data) {{
            current = data;
            hide('loading', true);
            hide('summary', false);

            byId('orderNumber').textContent = data.orderNumber || '-';
            byId('customerName').textContent = data.customerName || '-';
            byId('recipientName').textContent = data.recipientName || '-';
            byId('phone').textContent = data.customerPhone || '-';
            byId('address').textContent = data.deliveryAddress || '-';
            byId('slot').textContent = data.timeSlot || '-';
            byId('occasion').textContent = data.occasion || '-';
            byId('products').textContent = data.productSummary || '-';
            byId('status').textContent = data.status || '-';
            byId('mapsLink').href = data.mapsUrl || 'https://www.google.com/maps';

            byId('tripCustomer').textContent = data.customerName || '-';
            byId('tripRecipient').textContent = data.recipientName || '-';
            byId('tripPhone').textContent = data.customerPhone || '-';
            byId('tripAddress').textContent = data.deliveryAddress || '-';
            byId('tripEta').textContent = data.eta ? new Date(data.eta).toLocaleTimeString() : 'Calculating...';

            byId('callLink').href = data.customerPhone ? ('tel:' + data.customerPhone) : '#';
            byId('navLink').href = data.mapsUrl || 'https://www.google.com/maps';

            hide('photoRow', !data.requirePhotoProof);
            hide('otpRow', !data.requireOtp);
            hide('sigRow', !data.requireSignature);
            hide('proofBox', !(data.requirePhotoProof || data.requireOtp || data.requireSignature));

            const s = normalizeStatus(data.status);
            const done = s === 'delivered' || s === 'cancelled' || s === 'settlementcompleted';
            const waiting = s === 'assigned';
            const accepted = s === 'accepted';
            const traveling = s === 'outfordelivery' || s === 'arrivednearby';

            hide('acceptCard', !waiting);
            hide('startCard', !accepted);
            hide('travelCard', !traveling);

            if (traveling) {{
                startTracking();
                flushQueue();
            }} else {{
                stopTracking();
            }}

            if (done) {{
                hide('acceptCard', true);
                hide('startCard', true);
                hide('travelCard', true);
            }}
        }}

        async function refresh() {{
            const data = await getJson('/delivery/' + encodeURIComponent(token));
            render(data);
        }}

        async function acceptDelivery() {{
            byId('acceptErr').textContent = '';
            try {{
                await getJson('/delivery/' + encodeURIComponent(token) + '/accept', {{ method: 'POST', headers: {{ 'Content-Type': 'application/json' }}, body: '{{}}' }});
                await refresh();
            }} catch (err) {{
                byId('acceptErr').textContent = err.message || String(err);
            }}
        }}

        async function rejectDelivery() {{
            byId('acceptErr').textContent = '';
            const ok = confirm('Reject this delivery assignment?');
            if (!ok) return;
            try {{
                await getJson('/delivery/' + encodeURIComponent(token) + '/reject', {{ method: 'POST', headers: {{ 'Content-Type': 'application/json' }}, body: '{{}}' }});
                await refresh();
            }} catch (err) {{
                byId('acceptErr').textContent = err.message || String(err);
            }}
        }}

        async function requestLocationPermission() {{
            if (!navigator.geolocation) throw new Error('Location is not available on this device.');
            await new Promise((resolve, reject) => navigator.geolocation.getCurrentPosition(resolve, reject, {{ enableHighAccuracy: true, timeout: 12000 }}));
        }}

        async function startDelivery() {{
            byId('startErr').textContent = '';
            hide('retryPermissionBtn', true);
            try {{
                await requestLocationPermission();
            }} catch {{
                byId('startErr').textContent = 'Location permission is required to start delivery. Please enable GPS permission and retry.';
                hide('retryPermissionBtn', false);
                return;
            }}

            try {{
                await getJson('/delivery/' + encodeURIComponent(token) + '/start', {{ method: 'POST', headers: {{ 'Content-Type': 'application/json' }}, body: '{{}}' }});
                await refresh();
            }} catch (err) {{
                byId('startErr').textContent = err.message || String(err);
            }}
        }}

        async function postLocation(lat, lng, recordedAt, allowQueue) {{
            const payload = {{ latitude: lat, longitude: lng, recordedAt: recordedAt || new Date().toISOString() }};
            try {{
                await getJson('/delivery/' + encodeURIComponent(token) + '/location', {{
                    method: 'POST',
                    headers: {{ 'Content-Type': 'application/json' }},
                    body: JSON.stringify(payload)
                }});
            }} catch (err) {{
                if (allowQueue) queuePoint(payload);
                throw err;
            }}
        }}

        async function pushLocation(lat, lng) {{
            const now = Date.now();
            const interval = Math.max(15, Math.min(30, parseInt(current?.locationUploadIntervalSeconds || 20, 10) || 20));
            if (now - lastPush < interval * 1000) return;
            lastPush = now;

            try {{
                await postLocation(lat, lng, new Date().toISOString(), true);
            }} catch {{
                byId('gpsStatus').textContent = 'Offline - location queued';
            }}
        }}

        function startTracking() {{
            if (watchId !== null || !navigator.geolocation) return;
            byId('gpsStatus').textContent = 'GPS Active';
            watchId = navigator.geolocation.watchPosition(
                pos => pushLocation(pos.coords.latitude, pos.coords.longitude),
                () => {{ byId('gpsStatus').textContent = 'Waiting for Driver Location'; }},
                {{ enableHighAccuracy: true, maximumAge: 5000, timeout: 12000 }}
            );
        }}

        function stopTracking() {{
            if (watchId !== null && navigator.geolocation) navigator.geolocation.clearWatch(watchId);
            watchId = null;
        }}

        async function completeDelivery() {{
            byId('completeErr').textContent = '';
            const ok = confirm('Delivery Successful?');
            if (!ok) return;

            const body = {{}};
            if (current?.requirePhotoProof && byId('photoEnabled').checked) body.photoUrl = byId('photoInput').value || null;
            if (current?.requireOtp && byId('otpEnabled').checked) body.otp = byId('otpInput').value || null;
            if (current?.requireSignature && byId('sigEnabled').checked) body.signature = byId('sigInput').value || null;

            try {{
                await getJson('/delivery/' + encodeURIComponent(token) + '/complete', {{ method: 'POST', headers: {{ 'Content-Type': 'application/json' }}, body: JSON.stringify(body) }});
                stopTracking();
                await flushQueue();
                await refresh();
            }} catch (err) {{
                byId('completeErr').textContent = err.message || String(err);
            }}
        }}

        byId('acceptBtn').addEventListener('click', acceptDelivery);
        byId('rejectBtn').addEventListener('click', rejectDelivery);
        byId('startBtn').addEventListener('click', startDelivery);
        byId('retryPermissionBtn').addEventListener('click', startDelivery);
        byId('completeBtn').addEventListener('click', completeDelivery);
        byId('photoEnabled').addEventListener('change', () => hide('photoInput', !byId('photoEnabled').checked));
        byId('otpEnabled').addEventListener('change', () => hide('otpInput', !byId('otpEnabled').checked));
        byId('sigEnabled').addEventListener('change', () => hide('sigInput', !byId('sigEnabled').checked));

        window.addEventListener('online', () => flushQueue());
        setInterval(() => refresh().catch(() => {{}}), 20000);

        refresh().catch(err => {{
            hide('loading', true);
            hide('error', false);
            byId('error').textContent = err.message || String(err);
        }});
    </script>
</body>
</html>";

                return Content(html, "text/html");
        }

        [HttpPost("/delivery/{token}/start")]
        [AllowAnonymous]
        public async Task<IActionResult> StartDeliveryByToken(string token)
        {
                var delivery = await _db.Deliveries.FirstOrDefaultAsync(d => d.TrackingToken == token);
                if (delivery == null)
                        return NotFound(new { error = "Invalid tracking token" });

                if (delivery.Status is DeliveryStatus.Delivered or DeliveryStatus.Cancelled or DeliveryStatus.SettlementCompleted)
                        return BadRequest(new { error = "Delivery is already completed or cancelled" });

            if (delivery.Status == DeliveryStatus.Assigned)
                return BadRequest(new { error = "Accept delivery first." });

            var driverId = delivery.DeliveryPersonId ?? Guid.NewGuid();
                if (delivery.Status == DeliveryStatus.Accepted)
                        delivery.MarkPickedUp();
                if (delivery.Status == DeliveryStatus.PickedUp)
                        delivery.MarkOutForDelivery();

            if (delivery.Status != DeliveryStatus.OutForDelivery && delivery.Status != DeliveryStatus.ArrivedNearby)
                        return BadRequest(new { error = "Delivery cannot be started from the current status" });

                await _db.SaveChangesAsync();
                return Ok(new
                {
                        success = true,
                        status = delivery.Status.ToString(),
                        startedAtUtc = delivery.StartedAtUtc
                });
        }

        [HttpPost("/delivery/{token}/location")]
        [AllowAnonymous]
        public async Task<IActionResult> UploadLocationByToken(string token, [FromBody] TokenRouteLocationRequest request)
        {
            if (request.Latitude is < -90 or > 90)
                return BadRequest(new { error = "Invalid latitude" });
            if (request.Longitude is < -180 or > 180)
                return BadRequest(new { error = "Invalid longitude" });

            var delivery = await _db.Deliveries.FirstOrDefaultAsync(d => d.TrackingToken == token);
            if (delivery == null)
                return NotFound(new { error = "Invalid tracking token" });

            if (delivery.Status is DeliveryStatus.Delivered or DeliveryStatus.Cancelled or DeliveryStatus.SettlementCompleted)
                return BadRequest(new { error = "Delivery is already completed or cancelled" });

            if (delivery.Status != DeliveryStatus.OutForDelivery &&
                delivery.Status != DeliveryStatus.ArrivedNearby)
                return BadRequest(new { error = "Waiting for Driver Location" });

            var driverId = delivery.DeliveryPersonId ?? Guid.NewGuid();
            var recordedAt = request.RecordedAt ?? DateTime.UtcNow;

            await _journeyService.UploadLocationAsync(driverId, new UploadLocationRequest
            {
                DeliveryId = delivery.Id,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Accuracy = request.Accuracy,
                Speed = request.Speed,
                Heading = request.Heading,
                RecordedAt = recordedAt
            });

            delivery.SetLastLocationUtc(recordedAt);
            await _db.SaveChangesAsync();

            return Ok(new { success = true, lastLocationUtc = delivery.LastLocationUtc });
        }

        [HttpPost("/delivery/{token}/complete")]
        [AllowAnonymous]
        public async Task<IActionResult> CompleteDeliveryByToken(string token, [FromBody] TokenCompleteDeliveryRequest? request)
        {
                var delivery = await _db.Deliveries.FirstOrDefaultAsync(d => d.TrackingToken == token);
                if (delivery == null)
                        return NotFound(new { error = "Invalid tracking token" });

                if (delivery.Status == DeliveryStatus.Delivered)
                {
                        return Ok(new
                        {
                                success = true,
                                status = delivery.Status.ToString(),
                                completedAtUtc = delivery.CompletedAtUtc
                        });
                }

                if (delivery.Status == DeliveryStatus.OutForDelivery)
                        delivery.MarkArrivedNearby();

                if (delivery.Status != DeliveryStatus.ArrivedNearby)
                        return BadRequest(new { error = "Delivery can be completed only after start" });

                var settings = await TryGetDeliverySettingsAsync(delivery.CompanyId);
                var requirePhoto = settings?.RequirePhotoProof ?? false;
                var requireOtp = settings?.RequireOTP ?? false;
                var requireSignature = settings?.RequireSignature ?? false;

                if (requirePhoto && string.IsNullOrWhiteSpace(request?.PhotoUrl))
                    return BadRequest(new { error = "Photo proof is required." });
                if (requireOtp && string.IsNullOrWhiteSpace(request?.Otp))
                    return BadRequest(new { error = "OTP is required." });
                if (requireSignature && string.IsNullOrWhiteSpace(request?.Signature))
                    return BadRequest(new { error = "Customer signature is required." });

                if (request != null &&
                    (!string.IsNullOrWhiteSpace(request.PhotoUrl) ||
                     !string.IsNullOrWhiteSpace(request.Otp) ||
                     !string.IsNullOrWhiteSpace(request.Signature)))
                {
                    var existingProof = await _db.DeliveryProofs
                        .OrderByDescending(p => p.RecordedAt)
                        .FirstOrDefaultAsync(p => p.DeliveryId == delivery.Id);

                    if (existingProof == null && !string.IsNullOrWhiteSpace(request.PhotoUrl))
                    {
                        var proof = new DeliveryProof(
                            delivery.Id,
                            request.PhotoUrl.Trim(),
                            recipientName: request.RecipientName,
                            note: request.Note,
                            otpCode: string.IsNullOrWhiteSpace(request.Otp) ? null : request.Otp.Trim());

                        if (!string.IsNullOrWhiteSpace(request.Signature))
                            proof.SetSignature(request.Signature.Trim());
                        if (!string.IsNullOrWhiteSpace(request.Otp))
                            proof.VerifyOTP(request.Otp.Trim());

                        _db.DeliveryProofs.Add(proof);
                    }
                }

                delivery.MarkDelivered();
                await _db.SaveChangesAsync();

                return Ok(new
                {
                        success = true,
                        status = delivery.Status.ToString(),
                        completedAtUtc = delivery.CompletedAtUtc,
                        proof = new
                        {
                                photoUrl = request?.PhotoUrl,
                                otp = request?.Otp,
                                signature = request?.Signature
                        }
                });
        }

        private static string BuildMapsSearchUrl(string? address)
        {
                if (string.IsNullOrWhiteSpace(address))
                        return "https://www.google.com/maps";

                return $"https://www.google.com/maps/search/?api=1&query={Uri.EscapeDataString(address)}";
        }

    /// <summary>
    /// Android App Link redirect for Driver Start Link
    /// Returns HTML that attempts to open the Floraprise app with the delivery token
    /// Falls back to web view if app is not installed
    /// </summary>
    [HttpGet("driver/app-link/{token}")]
    public IActionResult GetDriverAppLink(string token)
    {
        var appLink = $"floraprise://driver/{token}";
        var webLink = $"{Request.Scheme}://{Request.Host}/d/{token}";
        
        var html = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Opening Floraprise...</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }}
        .container {{
            text-align: center;
            padding: 20px;
        }}
        .spinner {{
            border: 4px solid rgba(255,255,255,0.3);
            border-top: 4px solid white;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }}
        @keyframes spin {{
            0% {{ transform: rotate(0deg); }}
            100% {{ transform: rotate(360deg); }}
        }}
        .btn {{
            display: inline-block;
            margin-top: 20px;
            padding: 12px 24px;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='spinner'></div>
        <h2>Opening Floraprise App...</h2>
        <p>If the app doesn't open, you can:</p>
        <a href='{webLink}' class='btn'>Open in Browser</a>
    </div>
    <script>
        // Attempt to open app link
        window.location.href = '{appLink}';
        
        // Fallback to web view after delay
        setTimeout(function() {{
            window.location.href = '{webLink}';
        }}, 2000);
    </script>
</body>
</html>";

        return Content(html, "text/html");
    }

    /// <summary>
    /// Update delivery status using delivery token (no authentication required)
    /// Driver identity is validated via delivery token
    /// </summary>
    [HttpPost("driver/status")]
    [AllowAnonymous]
    public async Task<IActionResult> UpdateDeliveryStatus([FromBody] TokenBasedStatusUpdateRequest request)
    {
        try
        {
            // Find delivery by tracking token
            var delivery = await _db.Deliveries.FirstOrDefaultAsync(d => d.TrackingToken == request.TrackingToken);
            if (delivery == null)
                return NotFound(new { error = "Invalid tracking token" });

            if (delivery.Status is DeliveryStatus.Delivered or DeliveryStatus.Cancelled or DeliveryStatus.SettlementCompleted)
                return BadRequest(new { error = "Delivery is already completed or cancelled" });

            // Validate status transition
            var newStatus = Enum.Parse<DeliveryStatus>(request.Status);
            
            // Apply status update based on current state
            switch (newStatus)
            {
                case DeliveryStatus.Accepted:
                    if (delivery.Status != DeliveryStatus.Assigned)
                        return BadRequest(new { error = "Can only accept assigned deliveries" });
                    delivery.MarkAccepted(delivery.DeliveryPersonId ?? Guid.NewGuid());
                    break;
                    
                case DeliveryStatus.PickedUp:
                    if (delivery.Status != DeliveryStatus.Accepted)
                        return BadRequest(new { error = "Can only mark picked up after acceptance" });
                    delivery.MarkPickedUp();
                    break;
                    
                case DeliveryStatus.OutForDelivery:
                    if (delivery.Status != DeliveryStatus.PickedUp)
                        return BadRequest(new { error = "Can only mark out for delivery after pickup" });
                    delivery.MarkOutForDelivery();
                    break;
                    
                case DeliveryStatus.ArrivedNearby:
                    if (delivery.Status != DeliveryStatus.OutForDelivery)
                        return BadRequest(new { error = "Can only mark arrived nearby after out for delivery" });
                    delivery.MarkArrivedNearby();
                    break;
                    
                case DeliveryStatus.Delivered:
                    if (delivery.Status != DeliveryStatus.ArrivedNearby && delivery.Status != DeliveryStatus.OutForDelivery)
                        return BadRequest(new { error = "Can only mark delivered after arrived nearby or out for delivery" });
                    delivery.MarkDelivered();
                    break;
                    
                default:
                    return BadRequest(new { error = "Invalid status transition" });
            }

            await _db.SaveChangesAsync();
            
            return Ok(new { success = true, status = delivery.Status.ToString() });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Upload driver GPS location using delivery token (no authentication required)
    /// Driver identity is validated via delivery token + driver mobile number
    /// </summary>
    [HttpPost("driver/location")]
    [AllowAnonymous]
    public async Task<IActionResult> UploadDriverLocation([FromBody] TokenBasedLocationRequest request)
    {
        try
        {
            // Validate coordinates
            if (request.Latitude < -90 || request.Latitude > 90)
                return BadRequest(new { error = "Invalid latitude" });
            if (request.Longitude < -180 || request.Longitude > 180)
                return BadRequest(new { error = "Invalid longitude" });

            // Find delivery by tracking token
            var delivery = await _db.Deliveries.FirstOrDefaultAsync(d => d.TrackingToken == request.TrackingToken);
            if (delivery == null)
                return NotFound(new { error = "Invalid tracking token" });

            // Validate driver mobile number if provided
            if (!string.IsNullOrWhiteSpace(request.DriverMobile))
            {
                if (!delivery.DeliveryPersonId.HasValue)
                    return BadRequest(new { error = "Delivery has no assigned driver" });

                var assignedDriverPhone = await _db.Staff
                    .AsNoTracking()
                    .Where(s => s.Id == delivery.DeliveryPersonId.Value)
                    .Select(s => s.Phone)
                    .FirstOrDefaultAsync();

                if (string.IsNullOrWhiteSpace(assignedDriverPhone))
                    return BadRequest(new { error = "Assigned driver phone is not configured" });

                var provided = NormalizePhone(request.DriverMobile);
                var assigned = NormalizePhone(assignedDriverPhone);
                if (!string.Equals(provided, assigned, StringComparison.Ordinal))
                    return BadRequest(new { error = "Driver mobile does not match assigned driver" });
            }

            // Validate delivery is in active state
            if (delivery.Status != DeliveryStatus.OutForDelivery && 
                delivery.Status != DeliveryStatus.PickedUp &&
                delivery.Status != DeliveryStatus.Accepted)
                return BadRequest(new { error = "Delivery is not in active state" });

            // Upload location using the assigned driver ID (or create anonymous tracking)
            var driverId = delivery.DeliveryPersonId ?? Guid.NewGuid();
            var uploadRequest = new UploadLocationRequest
            {
                DeliveryId = delivery.Id,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Accuracy = request.Accuracy,
                Speed = request.Speed,
                Heading = request.Heading,
                RecordedAt = request.RecordedAt ?? DateTime.UtcNow
            };

            await _journeyService.UploadLocationAsync(driverId, uploadRequest);
            
            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get all live deliveries (for Owner Control Center)
    /// </summary>
    [HttpGet("live")]
    public async Task<IActionResult> GetLiveDeliveries()
    {
        try
        {
            var activeStatuses = new[] { DeliveryStatus.Assigned, DeliveryStatus.Accepted, DeliveryStatus.PickedUp, DeliveryStatus.OutForDelivery, DeliveryStatus.ArrivedNearby };
            
            var deliveries = await (
                from d in _db.Deliveries
                join s in _db.Orders on d.SalesOrderId equals s.Id
                join c in _db.Companies on s.CompanyId equals c.Id
                join customer in _db.Customers on s.CustomerId equals customer.Id
                join dp in _db.Staff on d.DeliveryPersonId equals dp.Id into dpGroup
                from dp in dpGroup.DefaultIfEmpty()
                // get latest GPS fix for this delivery
                let lastLoc = _db.DriverLocations
                    .Where(l => l.DeliveryId == d.Id)
                    .OrderByDescending(l => l.RecordedAt)
                    .FirstOrDefault()
                where activeStatuses.Contains(d.Status)
                select new
                {
                    DeliveryId    = d.Id,
                    OrderNumber   = s.OrderNumber,
                    CustomerName  = customer.Name,
                    CustomerPhone = d.CustomerPhone ?? s.RecipientPhone ?? customer.Phone,
                    FloristName   = c.Name,
                    DriverName    = dp != null ? dp.Name : "Unassigned",
                    DriverPhone   = dp != null ? dp.Phone : null,
                    Status        = d.Status.ToString(),
                    Eta           = d.DeliveryDate,
                    LastUpdate    = d.UpdatedAtUtc ?? d.CreatedAtUtc,
                    TrackingToken = d.TrackingToken,
                    DeliveryAddress = d.DeliveryAddress,
                    DestLat       = d.DeliveryAddressLatitude,
                    DestLng       = d.DeliveryAddressLongitude,
                    DriverLat     = lastLoc != null ? lastLoc.Latitude  : (double?)null,
                    DriverLng     = lastLoc != null ? lastLoc.Longitude : (double?)null,
                    DriverUpdatedAt = lastLoc != null ? lastLoc.RecordedAt : (DateTime?)null,
                })
                .OrderByDescending(x => x.LastUpdate)
                .Take(100)
                .ToListAsync();

            return Ok(deliveries);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Generate tracking token for a delivery (internal use)
    /// </summary>
    [HttpPost("generate-token")]
    [Authorize(Policy = "CompanyOnly")]
    public async Task<IActionResult> GenerateTrackingToken([FromBody] GenerateTokenRequest request)
    {
        try
        {
            var delivery = await _db.Deliveries.FindAsync(request.DeliveryId);
            if (delivery == null)
            {
                return NotFound(new { error = "Delivery not found" });
            }

            var token = string.IsNullOrWhiteSpace(delivery.TrackingToken)
                ? Guid.NewGuid().ToString("N")
                : delivery.TrackingToken!;

            delivery.SetTrackingToken(token);
            await _db.SaveChangesAsync();

            // Generate links
            var baseUrl = ResolvePublicBaseUrl();
            var driverLink = $"{baseUrl}/delivery/start/{token}";
            var customerLink = $"{baseUrl}/api/public/tracking/customer/{token}";
            var driverWhatsAppLink = $"https://wa.me/?text={Uri.EscapeDataString($"Start delivery: {driverLink}")}";
            var customerWhatsAppLink = $"https://wa.me/?text={Uri.EscapeDataString($"Track delivery: {customerLink}")}";

            return Ok(new 
            { 
                token = delivery.TrackingToken,
                driverLink = driverLink,
                customerLink = customerLink,
                driverWhatsAppLink = driverWhatsAppLink,
                customerWhatsAppLink = customerWhatsAppLink
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}

public class GenerateTokenRequest
{
    public Guid DeliveryId { get; set; }
}

public class TokenBasedLocationRequest
{
    public string TrackingToken { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Heading { get; set; }
    public DateTime? RecordedAt { get; set; }
    public string? DriverMobile { get; set; }
}

public class TokenBasedStatusUpdateRequest
{
    public string TrackingToken { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

public class TokenRouteLocationRequest
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Heading { get; set; }
    public DateTime? RecordedAt { get; set; }
}

public class TokenCompleteDeliveryRequest
{
    public string? PhotoUrl { get; set; }
    public string? Otp { get; set; }
    public string? Signature { get; set; }
    public string? Note { get; set; }
    public string? RecipientName { get; set; }
}
