using Sumpooj.Application.Common;
using Sumpooj.Application.Events;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class EventService
{
    private readonly IEventRepository _eventRepository;

    public EventService(IEventRepository eventRepository)
    {
        _eventRepository = eventRepository;
    }

    public async Task<EventDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var evt = await _eventRepository.GetByIdAsync(companyId, id);
        return evt == null ? null : MapToDto(evt);
    }

    public async Task<PagedResult<EventListDto>> SearchAsync(Guid companyId, EventSearchRequest request)
    {
        return await _eventRepository.SearchAsync(companyId, request);
    }

    public async Task<List<EventListDto>> GetUpcomingAsync(Guid companyId, int days = 30)
    {
        return await _eventRepository.GetUpcomingAsync(companyId, days);
    }

    public async Task<Guid> CreateAsync(Guid companyId, CreateEventRequest request)
    {
        var eventType = Enum.TryParse<EventType>(request.EventType, true, out var et) 
            ? et : EventType.Wedding;

        var evt = new Event(
            companyId,
            request.EventName,
            eventType,
            request.EventDate,
            request.ClientName,
            request.ClientPhone,
            request.VenueName);

        if (request.ClientEmail != null || request.VenueAddress != null)
        {
            evt.UpdateDetails(
                request.EventName,
                eventType,
                request.EventDate,
                request.VenueName,
                request.VenueAddress);
            evt.UpdateClientInfo(request.ClientName, request.ClientPhone, request.ClientEmail);
        }

        evt.SetEventDetails(
            request.EstimatedGuestCount,
            request.Budget,
            request.ColorTheme,
            request.MoodNotes,
            request.MoodBoardLink);

        if (request.AssignedDesignerId.HasValue)
        {
            evt.AssignDesigner(request.AssignedDesignerId.Value);
        }

        if (request.Status != null && Enum.TryParse<EventStatus>(request.Status, true, out var status))
        {
            evt.SetStatus(status);
        }

        if (request.InternalNotes != null)
        {
            evt.AddNote(request.InternalNotes);
        }

        await _eventRepository.AddAsync(evt);
        return evt.Id;
    }

    public async Task UpdateAsync(Guid companyId, Guid id, UpdateEventRequest request)
    {
        var evt = await _eventRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Event not found");

        if (request.EventName != null || request.EventType != null || request.EventDate != null ||
            request.VenueName != null || request.VenueAddress != null)
        {
            var eventType = request.EventType != null && Enum.TryParse<EventType>(request.EventType, true, out var et)
                ? et : evt.EventType;

            evt.UpdateDetails(
                request.EventName ?? evt.EventName,
                eventType,
                request.EventDate ?? evt.EventDate,
                request.VenueName ?? evt.VenueName,
                request.VenueAddress ?? evt.VenueAddress);
        }

        if (request.ClientName != null || request.ClientPhone != null || request.ClientEmail != null)
        {
            evt.UpdateClientInfo(
                request.ClientName ?? evt.ClientName,
                request.ClientPhone ?? evt.ClientPhone,
                request.ClientEmail ?? evt.ClientEmail);
        }

        if (request.EstimatedGuestCount != null || request.Budget != null || request.ColorTheme != null ||
            request.MoodNotes != null || request.MoodBoardLink != null)
        {
            evt.SetEventDetails(
                request.EstimatedGuestCount ?? evt.EstimatedGuestCount,
                request.Budget ?? evt.Budget,
                request.ColorTheme ?? evt.ColorTheme,
                request.MoodNotes ?? evt.MoodNotes,
                request.MoodBoardLink ?? evt.MoodBoardLink);
        }

        if (request.AssignedDesignerId.HasValue)
        {
            evt.AssignDesigner(request.AssignedDesignerId.Value);
        }

        if (request.Status != null && Enum.TryParse<EventStatus>(request.Status, true, out var status))
        {
            evt.SetStatus(status);
        }

        if (request.InternalNotes != null)
        {
            evt.AddNote(request.InternalNotes);
        }

        await _eventRepository.UpdateAsync(evt);
    }

    private static EventDto MapToDto(Event evt) => new()
    {
        Id = evt.Id,
        EventName = evt.EventName,
        EventType = evt.EventType.ToString(),
        EventDate = evt.EventDate,
        Status = evt.Status.ToString(),
        IsActive = evt.IsActive,
        ClientName = evt.ClientName,
        ClientPhone = evt.ClientPhone,
        ClientEmail = evt.ClientEmail,
        VenueName = evt.VenueName,
        VenueAddress = evt.VenueAddress,
        EstimatedGuestCount = evt.EstimatedGuestCount,
        Budget = evt.Budget,
        ColorTheme = evt.ColorTheme,
        MoodNotes = evt.MoodNotes,
        MoodBoardLink = evt.MoodBoardLink,
        AssignedDesignerId = evt.AssignedDesignerId,
        InternalNotes = evt.InternalNotes,
        TotalProposedAmount = evt.TotalProposedAmount,
        TotalPaidAmount = evt.TotalPaidAmount,
        EstimatedCost = evt.EstimatedCost,
        EstimatedProfit = evt.TotalProposedAmount - evt.EstimatedCost,
        CreatedAtUtc = evt.CreatedAtUtc
    };
}
