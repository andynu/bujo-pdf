# frozen_string_literal: true

require 'date'

module BujoPdf
  module Utilities
    # Dawn, sunrise, sunset and dusk for a date, as minutes after local midnight.
    #
    # Uses the NOAA solar calculator equations, accurate to about a minute at
    # mid latitudes. Dawn and dusk are civil twilight (sun 6 degrees below the
    # horizon). Times are US Eastern clock time, daylight saving included.
    #
    # Example:
    #   times = SunTimes.for(Date.new(2026, 12, 21))
    #   times.sunrise                  # => 430.4 (07:10)
    #   times.phase_at(6 * 60)         # => :night
    #   times.shaded_spans(960, 1020)  # => [[:twilight, 975.3, 1007.1], [:night, 1007.1, 1020]]
    class SunTimes < Data.define(:dawn, :sunrise, :sunset, :dusk)
      BOSTON_LATITUDE = 42.36
      BOSTON_LONGITUDE = -71.06

      SUNRISE_ZENITH = 90.833 # refraction plus the sun's radius
      CIVIL_ZENITH = 96.0

      # @param date [Date]
      # @param latitude [Float] degrees north
      # @param longitude [Float] degrees east (negative west)
      # @return [SunTimes]
      def self.for(date, latitude: BOSTON_LATITUDE, longitude: BOSTON_LONGITUDE)
        offset = eastern_utc_offset(date)
        noon, declination = solar_noon_and_declination(date, longitude, offset)

        half_day = ->(zenith) { 4 * hour_angle(latitude, declination, zenith) }
        sun = half_day.call(SUNRISE_ZENITH)
        civil = half_day.call(CIVIL_ZENITH)

        new(dawn: noon - civil, sunrise: noon - sun, sunset: noon + sun, dusk: noon + civil)
      end

      # US Eastern UTC offset in effect for most of a date's daylight hours.
      #
      # DST runs from the second Sunday in March to the first Sunday in
      # November (the rule since 2007). Both switches happen at 2 AM, before
      # dawn, so the changeover day itself takes the new offset.
      #
      # @param date [Date]
      # @return [Integer] -4 or -5
      def self.eastern_utc_offset(date)
        dst_start = nth_sunday(date.year, 3, 2)
        dst_end = nth_sunday(date.year, 11, 1)
        date >= dst_start && date < dst_end ? -4 : -5
      end

      def self.nth_sunday(year, month, nth)
        first = Date.new(year, month, 1)
        first + ((7 - first.wday) % 7) + ((nth - 1) * 7)
      end
      private_class_method :nth_sunday

      # @return [Array(Float, Float)] solar noon in local minutes, declination in degrees
      def self.solar_noon_and_declination(date, longitude, offset)
        julian_day = date.jd - 0.5 + ((12 - offset) / 24.0)
        t = (julian_day - 2_451_545.0) / 36_525.0

        mean_longitude = (280.46646 + (t * (36_000.76983 + (t * 0.0003032)))) % 360
        mean_anomaly = 357.52911 + (t * (35_999.05029 - (0.0001537 * t)))
        eccentricity = 0.016708634 - (t * (0.000042037 + (0.0000001267 * t)))

        m = radians(mean_anomaly)
        center = (Math.sin(m) * (1.914602 - (t * (0.004817 + (0.000014 * t))))) +
                 (Math.sin(2 * m) * (0.019993 - (0.000101 * t))) +
                 (Math.sin(3 * m) * 0.000289)

        omega = radians(125.04 - (1934.136 * t))
        apparent_longitude = radians(mean_longitude + center - 0.00569 - (0.00478 * Math.sin(omega)))

        mean_obliquity = 23 + ((26 + ((21.448 - (t * (46.815 + (t * (0.00059 - (t * 0.001813)))))) / 60)) / 60)
        obliquity = radians(mean_obliquity + (0.00256 * Math.cos(omega)))

        declination = degrees(Math.asin(Math.sin(obliquity) * Math.sin(apparent_longitude)))

        l0 = radians(mean_longitude)
        y = Math.tan(obliquity / 2)**2
        equation_of_time = 4 * degrees(
          (y * Math.sin(2 * l0)) -
          (2 * eccentricity * Math.sin(m)) +
          (4 * eccentricity * y * Math.sin(m) * Math.cos(2 * l0)) -
          (0.5 * y * y * Math.sin(4 * l0)) -
          (1.25 * eccentricity * eccentricity * Math.sin(2 * m))
        )

        noon = 720 - (4 * longitude) - equation_of_time + (offset * 60)
        [noon, declination]
      end
      private_class_method :solar_noon_and_declination

      # @return [Float] hour angle in degrees for the sun at the given zenith
      def self.hour_angle(latitude, declination, zenith)
        lat = radians(latitude)
        dec = radians(declination)
        cos_h = (Math.cos(radians(zenith)) / (Math.cos(lat) * Math.cos(dec))) - (Math.tan(lat) * Math.tan(dec))
        degrees(Math.acos(cos_h.clamp(-1.0, 1.0)))
      end
      private_class_method :hour_angle

      def self.radians(deg) = deg * Math::PI / 180
      def self.degrees(rad) = rad * 180 / Math::PI
      private_class_method :radians, :degrees

      # @param minute [Numeric] minutes after local midnight
      # @return [Symbol] :night, :twilight or :day
      def phase_at(minute)
        return :night if minute < dawn || minute >= dusk
        return :twilight if minute < sunrise || minute >= sunset

        :day
      end

      # Night and twilight stretches inside a window, in time order.
      #
      # @param from [Numeric] window start, minutes after local midnight
      # @param to [Numeric] window end
      # @return [Array<Array(Symbol, Float, Float)>] [phase, start, end] per stretch
      def shaded_spans(from, to)
        [
          [:night, 0, dawn],
          [:twilight, dawn, sunrise],
          [:twilight, sunset, dusk],
          [:night, dusk, 24 * 60]
        ].filter_map do |phase, start, finish|
          s = [start, from].max
          e = [finish, to].min
          [phase, s, e] if e > s
        end
      end
    end
  end
end
