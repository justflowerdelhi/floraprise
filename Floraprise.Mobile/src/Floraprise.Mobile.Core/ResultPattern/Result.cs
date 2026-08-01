namespace Floraprise.Mobile.Core.ResultPattern;

public class Result
{
    protected Result(bool isSuccess, string? error = null)
    {
        IsSuccess = isSuccess;
        Error = error;
    }

    public bool IsSuccess { get; }

    public bool IsFailure => !IsSuccess;

    public string? Error { get; }

    public static Result Success() => new(true);

    public static Result Fail(string error) => new(false, error);
}

public class Result<T> : Result
{
    protected Result(bool isSuccess, T? value = default, string? error = null)
        : base(isSuccess, error)
    {
        Value = value;
    }

    public T? Value { get; }

    public static Result<T> Success(T value) => new(true, value);

    public static new Result<T> Fail(string error) => new(false, default, error);
}
