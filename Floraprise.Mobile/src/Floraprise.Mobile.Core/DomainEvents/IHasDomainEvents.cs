namespace Floraprise.Mobile.Core.DomainEvents;

public interface IHasDomainEvents
{
    IReadOnlyCollection<IDomainEvent> DomainEvents { get; }

    void AddDomainEvent(IDomainEvent domainEvent);

    void ClearDomainEvents();
}
