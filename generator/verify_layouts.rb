# frozen_string_literal: true

require_relative "../lib/box2d/native"

probe = ARGV.fetch(0)
records = Hash.new { |hash, key| hash[key] = {offsets: {}} }

IO.popen([probe], &:read).each_line do |line|
  kind, c_name, name, value = line.chomp.split("\t")
  record = records[c_name]

  if kind == "S"
    record[:size] = Integer(name)
    record[:alignment] = Integer(value)
  else
    record[:offsets][name.to_sym] = Integer(value)
  end
end

records.each do |c_name, expected|
  klass = Box2D::Native.const_get(c_name.delete_prefix("b2"))
  actual = {
    size: klass.size,
    alignment: klass.alignment,
    offsets: expected[:offsets].to_h { |name, _offset| [name, klass.offset_of(name)] }
  }
  next if actual == expected

  abort "ABI mismatch for #{c_name}: C=#{expected.inspect}, FFI=#{actual.inspect}"
end

puts "verified #{records.length} Box2D struct layouts"
