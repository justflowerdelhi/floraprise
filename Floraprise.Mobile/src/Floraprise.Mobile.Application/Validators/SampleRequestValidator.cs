using FluentValidation;

namespace Floraprise.Mobile.Application.Validators;

public sealed class SampleRequestValidator : AbstractValidator<SampleRequest>
{
    public SampleRequestValidator()
    {
        RuleFor(x => x.Value).NotEmpty().MaximumLength(100);
    }
}

public sealed class SampleRequest
{
    public string? Value { get; set; }
}
