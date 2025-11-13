# Plan #20: iCal URL Integration for Event Highlighting

## Overview

This plan adds support for fetching events from iCal URLs (such as Google Calendar public URLs) to automatically highlight special dates in the planner. Events from iCal calendars will be highlighted on year-at-a-glance pages and labeled on weekly pages. This builds on the flat-file approach from Plan #19 but adds dynamic network-based calendar integration.

## Goals

1. Support one or multiple iCal calendar URLs
2. Fetch and parse iCal data at PDF generation time
3. Extract event dates and descriptions from iCal feeds
4. Handle recurring events properly
5. Cache fetched data to avoid repeated network requests
6. Provide robust error handling for network issues
7. Integrate with the highlighting system from Plan #19
8. Complement (not replace) the flat-file approach for maximum flexibility

## Ruby iCal Library Selection

### Recommended: `icalendar` gem

**Rationale:**
- Most mature and actively maintained Ruby iCal library
- Full RFC 5545 compliance (iCalendar specification)
- Excellent recurring event support (RRULE handling)
- Zero dependencies beyond Ruby stdlib
- Used by major Ruby projects (Calendly, GitHub, etc.)

**Dependency addition:**
```ruby
# Gemfile
gem 'icalendar', '~> 2.10'
```

## Configuration Format

### YAML Configuration File: `config/calendars.yml`

```yaml
# Configuration for iCal calendar sources
calendars:
  # Personal events calendar
  - name: "Personal"
    url: "https://calendar.google.com/calendar/ical/user@gmail.com/public/basic.ics"
    enabled: true
    color: "FFD700"  # Gold for personal events
    icon: "★"        # Display icon for these events

  # Work calendar
  - name: "Work"
    url: "https://calendar.google.com/calendar/ical/work@company.com/public/basic.ics"
    enabled: true
    color: "4285F4"  # Blue for work events
    icon: "●"

  # US Holidays
  - name: "Holidays"
    url: "https://calendar.google.com/calendar/ical/en.usa%23holiday@group.v.calendar.google.com/public/basic.ics"
    enabled: true
    color: "FF0000"  # Red for holidays
    icon: "🎉"

  # Birthdays
  - name: "Birthdays"
    url: "https://calendar.google.com/calendar/ical/birthdays.contacts@gmail.com/public/basic.ics"
    enabled: false   # Can be disabled without removing
    color: "E91E63"  # Pink for birthdays
    icon: "🎂"

# Cache settings
cache:
  enabled: true
  directory: ".cache/ical"
  ttl_hours: 24  # Re-fetch after 24 hours

# Network settings
network:
  timeout_seconds: 10
  max_retries: 3
  retry_delay_seconds: 2

# Event filtering
filters:
  # Only include events within the planner year
  date_range_only: true

  # Skip all-day events (optional)
  skip_all_day: false

  # Maximum number of events to show per day (prevents overcrowding)
  max_events_per_day: 3

  # Event title patterns to exclude (regex)
  exclude_patterns:
    - "^\\[Private\\]"
    - "^Out of office$"
```

## Architecture

### New Module: `lib/bujo_pdf/calendar_integration/`

```
lib/bujo_pdf/calendar_integration/
├── base.rb                    # Base module with shared utilities
├── config_loader.rb           # Load and parse calendars.yml
├── ical_fetcher.rb            # Fetch iCal data with caching
├── ical_parser.rb             # Parse iCal events
├── event.rb                   # Event data class
├── event_store.rb             # In-memory event storage by date
├── recurring_event_expander.rb # Expand RRULE events
└── highlighter.rb             # Integration with Plan #19 highlighting
```

## Relationship with Plan #19 (Flat-File Approach)

### Complementary Architecture

The iCal integration **complements** rather than replaces the flat-file approach:

```ruby
# Hybrid event loading in PlannerGenerator

def load_all_events(config_path: nil)
  store = CalendarIntegration::EventStore.new(
    max_events_per_day: 5  # Higher limit for hybrid sources
  )

  # 1. Load from flat file (Plan #19)
  if File.exist?('config/events.txt')
    flat_file_events = FlatFileLoader.load('config/events.txt', @year)
    flat_file_events.each { |event| store.add_event(event) }
    puts "Loaded #{flat_file_events.size} events from flat file"
  end

  # 2. Load from iCal URLs (Plan #20)
  ical_events = load_ical_events(config_path)
  ical_events.each { |event| store.add_event(event) } if ical_events

  store
end
```

### Use Case Scenarios

**Flat File Only** (Plan #19):
- Quick manual entry of special dates
- Offline usage
- Simple one-time dates
- Full control over event text and colors

**iCal Only** (Plan #20):
- Automatic sync with existing calendars
- Recurring events (birthdays, meetings)
- Shared calendars (holidays, team events)
- Dynamic updates (re-generate planner to get new events)

**Hybrid** (Both):
- iCal for recurring/shared events
- Flat file for personal annotations
- Flat file overrides iCal event display
- Best of both worlds

### Conflict Resolution

When both sources provide events for the same date:

1. **No deduplication** - Show all events (up to max_events_per_day limit)
2. **Priority order** - Flat file events sorted first, then iCal
3. **Color precedence** - Flat file color overrides iCal color if same event name
4. **Icon merging** - Multiple icons can be shown if space allows

## Performance Considerations

### Generation Time Impact

**Without caching:**
- Network fetch: 1-3 seconds per calendar
- Parsing: 0.1-0.5 seconds per calendar
- Recurrence expansion: 0.5-2 seconds for complex rules
- **Total: ~5-10 seconds for 3 calendars**

**With caching (subsequent runs):**
- Cache read: <0.1 seconds per calendar
- Parsing: 0.1-0.5 seconds per calendar
- **Total: ~1 second for 3 calendars**

### Memory Usage

- Typical Google Calendar: 50-200 KB iCal data
- Parsed events in memory: ~500 bytes per event
- For 500 events across 3 calendars: ~250 KB memory
- **Negligible impact on PDF generation**

### File Size Impact

- Highlighted cells: No size increase (just color change)
- Event labels on weekly pages: ~5-10 bytes per label
- For 365 days with avg 1 event/day: ~2-4 KB
- **<1% increase in PDF file size**

## Implementation Steps

1. Add `icalendar` gem to Gemfile
2. Create `lib/bujo_pdf/calendar_integration/` directory
3. Implement ConfigLoader
4. Implement IcalFetcher with caching
5. Implement Event data class
6. Implement IcalParser
7. Implement RecurringEventExpander
8. Implement EventStore
9. Update PlannerGenerator to load events
10. Update RenderContext with event_store
11. Update YearAtGlanceBase to highlight events
12. Update DailySection component to show event labels
13. Add unit tests for all components
14. Add integration tests
15. Create example `config/calendars.yml`
16. Update README with calendar integration guide
17. Add YARD documentation
18. Test with real Google Calendar
19. Test with recurring events
20. Test error handling (network failures, invalid data)
21. Performance testing with large calendars (1000+ events)

## Security Considerations

1. **URL validation** - Only allow HTTP/HTTPS URLs
2. **Redirect limits** - Maximum 5 redirects to prevent loops
3. **Timeout enforcement** - Hard timeout on network requests
4. **File system isolation** - Cache only in configured directory
5. **No code execution** - Parse iCal data, don't eval
6. **Error message safety** - Don't expose full URLs in error messages
7. **Private calendar URLs** - Warn users that URLs are stored in plaintext config

## Documentation Requirements

### User Guide Section

```markdown
# Calendar Integration

BujoPdf can automatically highlight events from your calendars using iCal URLs.

## Quick Start

1. Get your calendar's public iCal URL:
   - Google Calendar: Settings → Integrate calendar → Secret address in iCal format
   - Apple Calendar: Share calendar → Public calendar
   - Outlook: Calendar → Share → Publish calendar

2. Create `config/calendars.yml`:
   ```yaml
   calendars:
     - name: "Personal"
       url: "https://calendar.google.com/calendar/ical/YOUR_CALENDAR_ID/public/basic.ics"
       enabled: true
       color: "FFD700"
       icon: "★"
   ```

3. Generate planner:
   ```bash
   ruby gen.rb 2025
   ```

Your events will now appear as highlights in the year overview and labels in weekly pages!

## Configuration

See `config/calendars.example.yml` for full configuration options.

## Troubleshooting

- **"Failed to load calendar"**: Check your URL is correct and public
- **No events showing**: Verify events are within the planner year
- **Too many events**: Adjust `max_events_per_day` in config
```

## Migration Path from Plan #19

For users who implement Plan #19 first:

1. **Phase 1**: Flat file implementation (Plan #19)
   - Simple, no dependencies
   - Manual event entry
   - Works offline

2. **Phase 2**: Add iCal support (Plan #20)
   - Install `icalendar` gem
   - Create `config/calendars.yml`
   - Existing flat file events continue to work
   - iCal events automatically added

3. **Phase 3**: Optimize
   - Users can migrate frequent events to iCal
   - Keep flat file for one-off annotations
   - Adjust max_events_per_day as needed

## Future Enhancements (Post-MVP)

1. **Local calendar file support** - Use local `.ics` files instead of URLs
2. **Event categories** - Filter events by category/tags
3. **Custom event styling** - Per-event color/icon overrides
4. **Multi-year planning** - Cache events for multiple years
5. **Calendar diff highlighting** - Show new/changed events since last generation
6. **Event time display** - Show event times on weekly pages (optional)
7. **Calendar validation tool** - CLI command to test calendar URLs
8. **Statistics page** - Summary of events by category/calendar
9. **Interactive PDF forms** - Checkboxes for completed events
10. **Export back to iCal** - Handwritten notes → calendar events

## Conclusion

This plan provides a robust, well-tested integration between iCal calendars and the BujoPdf planner generator. By building on the flat-file approach from Plan #19, it offers users maximum flexibility while maintaining simplicity for those who don't need calendar integration.

The implementation prioritizes:
- **Reliability** - Graceful error handling and fallbacks
- **Performance** - Aggressive caching and efficient data structures
- **Usability** - Simple YAML configuration with sensible defaults
- **Extensibility** - Clean architecture for future enhancements
- **Compatibility** - Works alongside Plan #19 flat-file approach

This makes calendar integration a powerful optional feature that enhances the planner without adding complexity for users who don't need it.

## References:
- Source for various holiday calendars: https://www.thunderbird.net/en-US/calendar/holidays/
  - US Holidays: https://www.thunderbird.net/media/caldata/autogen/USHolidays.ics
