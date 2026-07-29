# frozen_string_literal: true

class Box2DDebugLines
  CIRCLE_SEGMENTS = 24

  attr_reader :positions, :colors

  def initialize
    clear
  end

  def clear
    @positions = []
    @colors = []
    self
  end

  def <<(command)
    type, *arguments = command
    case type
    when :polygon
      points, color = arguments
      add_loop(points, color)
    when :solid_polygon
      transform, points, _radius, color = arguments
      add_loop(transform_points(points, transform), color)
    when :circle
      center, radius, color = arguments
      add_circle(center, radius, color)
    when :solid_circle
      transform, radius, color = arguments
      add_circle(transform.fetch(:position), radius, color)
    when :solid_capsule
      point1, point2, radius, color = arguments
      add_capsule(point1, point2, radius, color)
    when :segment
      point1, point2, color = arguments
      add_segment(point1, point2, color)
    when :transform
      add_transform(arguments.fetch(0))
    when :point
      point, _size, color = arguments
      add_point(point, color)
    end
    self
  end

  private

  def add_loop(points, color)
    return if points.empty?

    points.each_with_index do |point, index|
      add_segment(point, points[(index + 1) % points.length], color)
    end
  end

  def add_circle(center, radius, color)
    points = CIRCLE_SEGMENTS.times.map do |index|
      angle = index * Math::PI * 2 / CIRCLE_SEGMENTS
      [center[0] + Math.cos(angle) * radius, center[1] + Math.sin(angle) * radius]
    end
    add_loop(points, color)
  end

  def add_capsule(point1, point2, radius, color)
    add_circle(point1, radius, color)
    add_circle(point2, radius, color)
    dx = point2[0] - point1[0]
    dy = point2[1] - point1[1]
    length = Math.hypot(dx, dy)
    return if length.zero?

    normal = [-dy * radius / length, dx * radius / length]
    add_segment(offset(point1, normal), offset(point2, normal), color)
    add_segment(offset(point1, normal, -1), offset(point2, normal, -1), color)
  end

  def add_transform(transform)
    origin = transform.fetch(:position)
    angle = transform.fetch(:angle)
    x_axis = [origin[0] + Math.cos(angle) * 0.4, origin[1] + Math.sin(angle) * 0.4]
    y_axis = [origin[0] - Math.sin(angle) * 0.4, origin[1] + Math.cos(angle) * 0.4]
    add_segment(origin, x_axis, 0xFF0000)
    add_segment(origin, y_axis, 0x00FF00)
  end

  def add_point(point, color)
    add_segment([point[0] - 0.05, point[1]], [point[0] + 0.05, point[1]], color)
    add_segment([point[0], point[1] - 0.05], [point[0], point[1] + 0.05], color)
  end

  def add_segment(point1, point2, color)
    rgba = hex_color(color)
    @positions.push(point1.to_a, point2.to_a)
    @colors.push(rgba, rgba)
  end

  def transform_points(points, transform)
    position = transform.fetch(:position)
    angle = transform.fetch(:angle)
    cosine = Math.cos(angle)
    sine = Math.sin(angle)
    points.map do |x, y|
      [
        position[0] + x * cosine - y * sine,
        position[1] + x * sine + y * cosine
      ]
    end
  end

  def offset(point, normal, direction = 1)
    [point[0] + normal[0] * direction, point[1] + normal[1] * direction]
  end

  def hex_color(value)
    color = Integer(value) & 0xFFFFFF
    [
      ((color >> 16) & 0xFF) / 255.0,
      ((color >> 8) & 0xFF) / 255.0,
      (color & 0xFF) / 255.0,
      1.0
    ]
  end
end
