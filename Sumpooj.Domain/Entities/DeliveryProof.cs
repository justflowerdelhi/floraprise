namespace Sumpooj.Domain.Entities;

public class DeliveryProof : BaseEntity
{
    private DeliveryProof() { }

    public DeliveryProof(
        Guid deliveryId,
        string photoUrl,
        string? recipientName = null,
        string? note = null,
        string? otpCode = null,
        double? completionLatitude = null,
        double? completionLongitude = null)
    {
        if (deliveryId == Guid.Empty)
            throw new ArgumentException("DeliveryId is required.", nameof(deliveryId));
        if (string.IsNullOrWhiteSpace(photoUrl))
            throw new ArgumentException("PhotoUrl is required.", nameof(photoUrl));

        DeliveryId = deliveryId;
        PhotoUrl = photoUrl;
        RecipientName = recipientName;
        Note = note;
        OTPCode = otpCode;
        CompletionLatitude = completionLatitude;
        CompletionLongitude = completionLongitude;
        RecordedAt = DateTime.UtcNow;
    }

    public Guid DeliveryId { get; private set; }
    public string PhotoUrl { get; private set; }
    public string? RecipientName { get; private set; }
    public string? Note { get; private set; }
    public DateTime RecordedAt { get; private set; }

    // OTP verification
    public string? OTPCode { get; private set; }
    public bool OTPVerified { get; private set; }
    public DateTime? OTPVerifiedAt { get; private set; }

    // GPS coordinates at completion
    public double? CompletionLatitude { get; private set; }
    public double? CompletionLongitude { get; private set; }

    // Optional: Who uploaded the proof
    public Guid? UploadedByUserId { get; private set; }
    public string? UploadedByUserName { get; private set; }

    // Optional: Signature data if digital signature is captured
    public string? SignatureData { get; private set; }

    public void SetUploadContext(Guid? userId, string? userName)
    {
        UploadedByUserId = userId;
        UploadedByUserName = userName;
        MarkUpdated();
    }

    public void SetSignature(string? signatureData)
    {
        SignatureData = signatureData;
        MarkUpdated();
    }

    public void VerifyOTP(string enteredOTP)
    {
        if (string.IsNullOrWhiteSpace(OTPCode))
            throw new InvalidOperationException("No OTP code set for this delivery");

        if (OTPCode == enteredOTP)
        {
            OTPVerified = true;
            OTPVerifiedAt = DateTime.UtcNow;
            MarkUpdated();
        }
        else
        {
            throw new ArgumentException("Invalid OTP code");
        }
    }
}
