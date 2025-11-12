# Plan #17: Monthly Bookmarks in PDF Outline

## Overview
Add monthly groupings to the PDF outline/bookmarks (the navigation sidebar in PDF readers) to provide better hierarchical navigation from year to month to week. This does not add actual pages, only improves the bookmark structure.

## Current PDF Outline Structure
```
Planner 2025
├─ 2025 Overview
│  ├─ Seasonal Calendar
│  ├─ Year at a Glance - Events
│  ├─ Year at a Glance - Highlights
│  └─ Multi-Year Overview
├─ Weekly Pages (flat list of all 52-53 weeks)
└─ Templates
   ├─ Grid Reference & Calibration
   └─ Dot Grid
```

## New PDF Outline Structure
```
Planner 2025
├─ 2025 Overview
│  ├─ Seasonal Calendar
│  ├─ Year at a Glance - Events
│  ├─ Year at a Glance - Highlights
│  └─ Multi-Year Overview
├─ Monthly Pages
│  ├─ January 2025
│  │  ├─ Week 1
│  │  ├─ Week 2
│  │  ├─ Week 3
│  │  ├─ Week 4
│  │  └─ Week 5
│  ├─ February 2025
│  │  ├─ Week 5
│  │  ├─ Week 6
│  │  ├─ Week 7
│  │  └─ Week 8
│  └─ ... (through December)
└─ Templates
   ├─ Grid Reference & Calibration
   └─ Dot Grid
```

## Benefits

1. **Better navigation hierarchy**: Year → Month → Week flow in PDF reader sidebar
2. **Easier month-level navigation**: Users can quickly jump to a specific month
3. **Clearer organization**: Weeks are grouped by month rather than shown as a flat list
4. **No page count change**: This is a metadata-only change

## Implementation

### 1. Add weeks_for_month utility method
Add to `DateCalculator` class to determine which weeks belong to each month:

```ruby
def self.weeks_for_month(year, month)
  first_of_month = Date.new(year, month, 1)
  last_of_month = Date.new(year, month, -1)

  first_week = week_number_for_date(year, first_of_month)
  last_week = week_number_for_date(year, last_of_month)

  (first_week..last_week).to_a
end
```

### 2. Track week page numbers
Modify `generate_weekly_pages` to store page numbers in a hash:

```ruby
def generate_weekly_pages
  @weekly_start_page = @pdf.page_number + 1
  @week_pages = {}  # Track page numbers

  total_weeks.times do |i|
    week_num = i + 1
    @pdf.start_new_page
    generate_weekly_page(week_num)
    @week_pages[week_num] = @pdf.page_number  # Store page number
  end
end
```

### 3. Update build_outline method
Replace flat "Weekly Pages" section with monthly groupings:

```ruby
def build_outline
  @pdf.outline.define do
    section "#{@year} Overview", destination: @seasonal_page do
      # ... existing overview bookmarks
    end

    # Monthly groupings
    section 'Monthly Pages', destination: @weekly_start_page do
      (1..12).each do |month|
        month_name = Date::MONTHNAMES[month]
        weeks_in_month = Utilities::DateCalculator.weeks_for_month(@year, month)

        if weeks_in_month.any?
          first_week = weeks_in_month.first
          section "#{month_name} #{@year}", destination: @week_pages[first_week] do
            weeks_in_month.each do |week_num|
              page_num = @week_pages[week_num]
              page destination: page_num, title: "Week #{week_num}" if page_num
            end
          end
        end
      end
    end

    section 'Templates', destination: @reference_page do
      # ... existing template bookmarks
    end
  end
end
```

## Edge Cases

1. **Weeks spanning months**: A week may appear in bookmarks for two months
   - Week 5 (Jan 27 - Feb 2) appears in both January and February sections
   - This is expected and helpful for navigation

2. **53-week years**: December may have 5-6 weeks
   - Handled automatically by weeks_for_month logic

3. **First week of year**: Week 1 might start in late December
   - Appears in January section (where most days fall)

## Testing

1. Generate planner PDF
2. Open in PDF reader
3. Verify outline sidebar shows monthly groupings
4. Click each month section to verify navigation
5. Verify weeks appear under correct months

## Files Modified

- `lib/bujo_pdf/utilities/date_calculator.rb` - Add weeks_for_month method
- `lib/bujo_pdf/planner_generator.rb` - Update generate_weekly_pages and build_outline

## Estimated Effort

- **Development time**: 30 minutes
- **Lines of code**: ~30 new/modified lines
- **Risk level**: Very low - only affects PDF metadata
