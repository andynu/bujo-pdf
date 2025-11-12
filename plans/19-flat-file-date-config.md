# Plan #19: Flat-File Configuration for Highlighted Dates

## Configuration File Format

Use **YAML** for the configuration file due to:
- Superior readability for date-centric data
- Native Ruby support without dependencies
- Comment support for documentation
- Clear hierarchical structure

### File Location and Naming
```
config/dates.yml
```

Place in a `config/` directory at the project root to separate configuration from code.

### Configuration Schema

```yaml
# config/dates.yml
year: 2025  # Optional: validate against generated year

dates:
  # Simple date with label
  - date: 2025-01-01
    label: "New Year"
    category: holiday

  # Date with custom colors
  - date: 2025-02-14
    label: "Valentine's Day"
    category: holiday
    color: "FF69B4"  # Pink

  # Recurring date (birthday, anniversary)
  - date: 2025-03-15
    label: "Birthday"
    category: personal

  # Work/project deadline
  - date: 2025-04-30
    label: "Q1 Report Due"
    category: work
    priority: high

# Category definitions with default colors
categories:
  holiday:
    color: "FFE5E5"      # Light red
    text_color: "CC0000" # Dark red
    icon: "★"

  personal:
    color: "E5F0FF"      # Light blue
    text_color: "0066CC"
    icon: "♦"

  work:
    color: "FFF5E5"      # Light orange
    text_color: "CC7700"
    icon: "■"

  other:
    color: "F0F0F0"      # Light gray
    text_color: "666666"
    icon: "●"

# Priority levels affect visual prominence
priorities:
  high:
    border_width: 1.5
    bold: true
  normal:
    border_width: 0.5
    bold: false
```

## Data Structure

### Internal Representation

```ruby
# lib/bujo_pdf/date_configuration.rb
module BujoPdf
  class DateConfiguration
    attr_reader :dates, :categories, :priorities

    class HighlightedDate
      attr_reader :date, :label, :category, :priority, :color, :text_color

      def initialize(date:, label:, category: 'other', priority: 'normal', color: nil, text_color: nil)
        @date = Date.parse(date.to_s)
        @label = label
        @category = category
        @priority = priority
        @color = color
        @text_color = text_color
      end

      def week_number(year_start_monday)
        days_from_start = (@date - year_start_monday).to_i
        (days_from_start / 7) + 1
      end

      def day_of_week
        @date.strftime('%A')
      end
    end

    def initialize(config_path = 'config/dates.yml')
      @config_path = config_path
      @dates = []
      @categories = default_categories
      @priorities = default_priorities
      load_config if File.exist?(@config_path)
    end

    def load_config
      config = YAML.load_file(@config_path)

      # Load category definitions
      @categories.merge!(config['categories']) if config['categories']
      @priorities.merge!(config['priorities']) if config['priorities']

      # Parse dates
      return unless config['dates']

      config['dates'].each do |date_config|
        @dates << HighlightedDate.new(**date_config.transform_keys(&:to_sym))
      end
    end

    def dates_for_month(month)
      @dates.select { |d| d.date.month == month }
    end

    def dates_for_week(week_num, year_start_monday)
      @dates.select { |d| d.week_number(year_start_monday) == week_num }
    end

    def date_for_day(date)
      @dates.find { |d| d.date == date }
    end

    def category_style(category_name)
      @categories[category_name] || @categories['other']
    end

    def priority_style(priority_name)
      @priorities[priority_name] || @priorities['normal']
    end

    private

    def default_categories
      {
        'holiday' => {
          'color' => 'FFE5E5',
          'text_color' => 'CC0000',
          'icon' => '★'
        },
        'personal' => {
          'color' => 'E5F0FF',
          'text_color' => '0066CC',
          'icon' => '♦'
        },
        'work' => {
          'color' => 'FFF5E5',
          'text_color' => 'CC7700',
          'icon' => '■'
        },
        'other' => {
          'color' => 'F0F0F0',
          'text_color' => '666666',
          'icon' => '●'
        }
      }
    end

    def default_priorities
      {
        'high' => { 'border_width' => 1.5, 'bold' => true },
        'normal' => { 'border_width' => 0.5, 'bold' => false }
      }
    end
  end
end
```

## Integration Points

### 1. PlannerGenerator Initialization

```ruby
# lib/bujo_pdf/planner_generator.rb
class PlannerGenerator
  def initialize(year, config_path: 'config/dates.yml')
    @year = year
    @date_config = BujoPdf::DateConfiguration.new(config_path)
    # ... existing initialization
  end

  # Pass @date_config to page generators that need it
end
```

### 2. Year-at-a-Glance Page Modifications

Modify `lib/bujo_pdf/pages/year_events.rb` and `year_highlights.rb`:

```ruby
# In render_month_grid method
def render_date_cell(date, cell_x, cell_y, cell_width, cell_height)
  highlighted_date = @date_config.date_for_day(date)

  if highlighted_date
    # Draw background highlight
    category_style = @date_config.category_style(highlighted_date.category)
    bg_color = highlighted_date.color || category_style['color']

    @pdf.fill_color bg_color
    @pdf.fill_rectangle([cell_x, cell_y], cell_width, cell_height)
    @pdf.fill_color '000000'  # Reset to black

    # Draw border if high priority
    priority_style = @date_config.priority_style(highlighted_date.priority)
    if priority_style['border_width'] > 0.5
      @pdf.stroke_color category_style['text_color']
      @pdf.line_width = priority_style['border_width']
      @pdf.stroke_rectangle([cell_x, cell_y], cell_width, cell_height)
      @pdf.line_width = 0.5  # Reset
      @pdf.stroke_color COLOR_BORDERS  # Reset
    end
  end

  # Draw date number (existing code)
  # ...

  # Add category icon if highlighted
  if highlighted_date
    category_style = @date_config.category_style(highlighted_date.category)
    icon = category_style['icon']

    @pdf.fill_color category_style['text_color']
    @pdf.text_box icon,
                  at: [cell_x + 2, cell_y - 2],
                  width: 8,
                  height: 8,
                  size: 6,
                  align: :left,
                  valign: :top
    @pdf.fill_color '000000'  # Reset
  end
end
```

### 3. Weekly Page Modifications

Modify `lib/bujo_pdf/pages/weekly_page.rb`:

```ruby
# In render_daily_section method
def render_daily_columns
  dates_for_week = @date_config.dates_for_week(@week_num, @year_start_monday)

  (0..6).each do |day_offset|
    current_date = week_start_date + day_offset
    highlighted_date = @date_config.date_for_day(current_date)

    # Existing column rendering...

    # Add date label if highlighted
    if highlighted_date
      render_date_label(highlighted_date, col_x, header_y, col_width)
    end
  end
end

def render_date_label(highlighted_date, x, y, width)
  category_style = @date_config.category_style(highlighted_date.category)
  priority_style = @date_config.priority_style(highlighted_date.priority)

  # Label box below date header
  label_height = 12
  label_y = y - WEEKLY_DAILY_HEADER_HEIGHT - 2

  # Background
  @pdf.fill_color category_style['color']
  @pdf.fill_rectangle([x + 2, label_y], width - 4, label_height)
  @pdf.fill_color '000000'

  # Text
  font_weight = priority_style['bold'] ? :bold : :normal
  @pdf.font('Helvetica', style: font_weight) if font_weight == :bold

  @pdf.fill_color category_style['text_color']
  @pdf.text_box highlighted_date.label,
                at: [x + 4, label_y - 1],
                width: width - 8,
                height: label_height - 2,
                size: 7,
                align: :center,
                valign: :center,
                overflow: :shrink_to_fit

  @pdf.fill_color '000000'
  @pdf.font('Helvetica')  # Reset font
end
```

## Visual Design Specifications

### Year-at-a-Glance Highlights

1. **Background Fill**: Category color at 20% opacity (achieved via lighter color values)
2. **Icon Overlay**: Category icon in top-left corner (6pt size)
3. **Border**: High-priority dates get 1.5pt colored border
4. **Date Number**: Remains black for readability

### Weekly Page Labels

1. **Position**: Directly below day header, inside daily column
2. **Height**: 12pt (approximately 0.85 grid boxes)
3. **Background**: Full category color
4. **Text**:
   - Size: 7pt
   - Color: Category text color (darker for contrast)
   - Weight: Bold for high-priority, normal otherwise
   - Truncation: `shrink_to_fit` to prevent overflow
5. **Padding**: 2pt horizontal margins

### Color Scheme Guidelines

**Contrast Requirements**:
- Background colors: Pastel/light tints (luminosity > 85%)
- Text colors: Darker shades of same hue (luminosity < 40%)
- Ensure WCAG AA contrast ratio (4.5:1 minimum)

**Default Palette**:
```ruby
HIGHLIGHT_COLORS = {
  holiday: { bg: 'FFE5E5', text: 'CC0000' },   # Red family
  personal: { bg: 'E5F0FF', text: '0066CC' },  # Blue family
  work: { bg: 'FFF5E5', text: 'CC7700' },      # Orange family
  other: { bg: 'F0F0F0', text: '666666' }      # Gray family
}
```

## Error Handling

```ruby
# In DateConfiguration#load_config
def load_config
  return unless File.exist?(@config_path)

  begin
    config = YAML.load_file(@config_path)

    # Validate structure
    unless config.is_a?(Hash)
      warn "Invalid config format in #{@config_path}"
      return
    end

    # Validate year if specified
    if config['year'] && config['year'] != @year
      warn "Config year (#{config['year']}) doesn't match generator year (#{@year})"
    end

    # Load with error handling per date
    config['dates']&.each do |date_config|
      @dates << HighlightedDate.new(**date_config.transform_keys(&:to_sym))
    rescue ArgumentError => e
      warn "Skipping invalid date: #{date_config.inspect} - #{e.message}"
    end

  rescue Psych::SyntaxError => e
    warn "YAML syntax error in #{@config_path}: #{e.message}"
  rescue => e
    warn "Error loading date configuration: #{e.message}"
  end
end
```

## Usage Example

```yaml
# config/dates.yml
year: 2025

dates:
  # US Federal Holidays
  - date: 2025-01-01
    label: "New Year's Day"
    category: holiday

  - date: 2025-01-20
    label: "MLK Day"
    category: holiday

  - date: 2025-07-04
    label: "Independence Day"
    category: holiday

  # Personal dates
  - date: 2025-06-15
    label: "Anniversary"
    category: personal
    priority: high

  - date: 2025-09-23
    label: "Birthday"
    category: personal
    priority: high

  # Work deadlines
  - date: 2025-03-31
    label: "Q1 Review"
    category: work
    priority: high

  - date: 2025-12-15
    label: "Annual Report"
    category: work
    priority: high
```

## Implementation Steps

1. **Create DateConfiguration class** (`lib/bujo_pdf/date_configuration.rb`)
2. **Add config directory and sample file** (`config/dates.yml.example`)
3. **Modify PlannerGenerator** to accept and instantiate DateConfiguration
4. **Update year-at-a-glance pages** to check for and render highlights
5. **Update weekly pages** to check for and render date labels
6. **Add tests** for DateConfiguration parsing and date lookups
7. **Update documentation** (CLAUDE.md) with configuration instructions
8. **Add .gitignore entry** for `config/dates.yml` (keep personal dates private)

## Future Enhancements

- **Recurring dates**: Support `recurrence: annual` for birthdays/anniversaries
- **Date ranges**: Multi-day events (vacations, conferences)
- **Import formats**: iCal/ICS integration for syncing with calendars
- **CLI tool**: `rake dates:validate` to check configuration
- **Multiple configs**: Support per-user overlay files (`dates.yml` + `dates.personal.yml`)
