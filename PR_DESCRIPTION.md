# Modernize codebase for Ruby 4.0 features

## Summary

Modernizes the bujo-pdf codebase to leverage Ruby 4.0 features, including Data classes, pattern matching improvements, the `it` parameter, and Range enhancements.

## Changes

### 1. Data Class Conversions ✨

**Week and Month classes now use `Data.define`:**

- ✅ Immutable by default (frozen objects)
- ✅ Automatic equality methods (`==`, `eql?`, `hash`)
- ✅ Built-in `to_h` and `deconstruct_keys` for pattern matching
- ✅ Better default `inspect` output

**Before:**
```ruby
class Week
  attr_reader :year, :number
  def initialize(year:, number:)
    @year = year
    @number = number
  end
  def ==(other)
    other.is_a?(Week) && year == other.year && number == other.number
  end
  def hash
    [year, number].hash
  end
end
```

**After:**
```ruby
Week = Data.define(:year, :number) do
  # Methods only - equality/hash/to_h automatic!
end
```

### 2. Pattern Matching with Ranges 🎯

**Cleaner seasonal logic using pattern matching:**

**Before:**
```ruby
case month
when 12, 1, 2
  'Winter'
when 3, 4, 5
  'Spring'
end
```

**After:**
```ruby
case month
in 12 | 1 | 2 then 'Winter'
in 3..5 then 'Spring'
in 6..8 then 'Summer'
in 9..11 then 'Fall'
end
```

### 3. `it` Parameter (Ruby 3.4+) 🔥

**Cleaner single-parameter blocks:**

**Before:**
```ruby
(1..12).each do |month|
  return Date::ABBR_MONTHNAMES[month][0..(char-1)] if first_week_of_month(year, month) == week_num
end
```

**After:**
```ruby
(1..12).find { first_week_of_month(year, it) == week_num }
       &.then { Date::ABBR_MONTHNAMES[it][0..(char-1)] }
```

### 4. Range#overlap? (Ruby 4.0) 📊

**New utility method for efficient range overlap detection:**

```ruby
def week_overlaps_month?(year, week_num, month)
  week_range = week_start(year, week_num)..week_end(year, week_num)
  month_range = Date.new(year, month, 1)..Date.new(year, month, -1)
  week_range.overlap?(month_range)  # Ruby 4.0 feature
end
```

## Benefits

| Benefit | Details |
|---------|---------|
| **Immutability** | Data objects are frozen, preventing accidental mutations |
| **Pattern Matching** | First-class support for destructuring value objects |
| **Less Boilerplate** | Data class eliminates 20+ lines of repetitive code |
| **Type Safety** | Data validates required fields at initialization |
| **Cleaner Code** | `it` parameter reduces noise in simple blocks |
| **Modern Ruby** | Leverages Ruby 4.0's latest language features |

## Requirements

- **Ruby 3.4+** for `it` parameter support
- **Ruby 4.0** for full feature compatibility (Range#overlap?, Set as core class)

## Testing

✅ Syntax validation passed
✅ Manual testing confirmed Week/Month Data classes work correctly
✅ Code is backward compatible with existing API (`Week.new(year:, number:)`)

## Pattern Matching Examples

With Data classes, you can now use pattern matching:

```ruby
case week
in Week[year: 2025, number: 1..10]
  puts "Early 2025 week"
in Week[year:, number:] if number > 50
  puts "Late year week"
end

case month
in Month[year: 2025, number: 1..3]
  puts "Q1 2025"
in Month[number: 12]
  puts "December"
end
```

## Files Changed

- `lib/bujo_pdf/week.rb` - Converted to Data class
- `lib/bujo_pdf/dsl/week.rb` - Converted Month to Data class, added `it` parameter
- `lib/bujo_pdf/utilities/date_calculator.rb` - Pattern matching, `it` parameter, Range#overlap?

## Related

This PR addresses the question about Ruby 4.0 modernization opportunities. While ractors don't provide significant parallelization benefits for PDF generation (due to Prawn's sequential requirements), Ruby 4.0's Data class, pattern matching, and syntax improvements offer substantial code quality improvements.
