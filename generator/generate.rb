# frozen_string_literal: true

require "ffi/clang"

module Box2DBindings
  ROOT = File.expand_path("..", __dir__)
  INCLUDE_ROOT = File.join(ROOT, "ext/box2d/vendor/box2d/include")
  HEADER = File.join(INCLUDE_ROOT, "box2d/box2d.h")
  OUTPUT = File.join(ROOT, "lib/box2d/native.rb")
  PROBE_OUTPUT = File.join(__dir__, "layout_probe.c")

  Field = Data.define(:name, :type, :offset)
  Struct = Data.define(:name, :ruby_name, :size, :alignment, :fields)
  Enum = Data.define(:name, :ruby_name, :values)
  Function = Data.define(:name, :arguments, :result)

  class TypeMapper
    FIXED_TYPES = {
      "int8_t" => ":int8",
      "uint8_t" => ":uint8",
      "int16_t" => ":int16",
      "uint16_t" => ":uint16",
      "int32_t" => ":int32",
      "uint32_t" => ":uint32",
      "int64_t" => ":int64",
      "uint64_t" => ":uint64",
      "size_t" => ":size_t"
    }.freeze

    PRIMITIVE_TYPES = {
      type_void: ":void",
      type_bool: ":bool",
      type_char_s: ":char",
      type_schar: ":int8",
      type_uchar: ":uint8",
      type_short: ":short",
      type_ushort: ":ushort",
      type_int: ":int",
      type_uint: ":uint",
      type_long: ":long",
      type_ulong: ":ulong",
      type_longlong: ":long_long",
      type_ulonglong: ":ulong_long",
      type_float: ":float",
      type_double: ":double"
    }.freeze

    def field(type)
      map(type, struct_by_value: true)
    end

    def parameter(type)
      map(type, struct_by_value: true)
    end

    private

    def map(type, struct_by_value:)
      spelling = type.spelling.sub(/\Aconst\s+/, "")
      return FIXED_TYPES.fetch(spelling) if FIXED_TYPES.key?(spelling)
      return ":pointer" if type.kind == :type_pointer
      return array(type) if type.kind == :type_constant_array

      canonical = canonical_type(type)
      primitive = PRIMITIVE_TYPES[canonical.kind]
      return primitive if primitive
      return ":int" if canonical.kind == :type_enum

      if canonical.kind == :type_record
        class_name = ruby_name(canonical.declaration.spelling)
        return struct_by_value ? "#{class_name}.by_value" : class_name
      end

      raise "unsupported C type #{type.spelling.inspect} (#{type.kind}, canonical #{canonical.kind})"
    end

    def canonical_type(type)
      return type.canonical if %i[type_elaborated type_typedef].include?(type.kind)

      type
    end

    def array(type)
      "[#{field(type.element_type)}, #{type.size}]"
    end

    def ruby_name(name)
      name.delete_prefix("b2")
    end
  end

  class Generator
    def initialize
      @mapper = TypeMapper.new
      @translation_unit = parse
      @structs = []
      @enums = []
      @functions = []
    end

    def run(check:)
      collect_declarations
      write_or_check(OUTPUT, render_bindings, check:)
      write_or_check(PROBE_OUTPUT, render_probe, check:)
    end

    private

    def parse
      index = FFI::Clang::Index.new
      unit = index.parse_translation_unit(
        HEADER,
        ["-x", "c", "-std=c17", "-I#{INCLUDE_ROOT}"]
      )
      errors = unit.diagnostics.select { |diagnostic| %i[error fatal].include?(diagnostic.severity) }
      abort errors.map(&:spelling).join("\n") unless errors.empty?

      unit
    end

    def collect_declarations
      api_names = exported_function_names

      @translation_unit.cursor.each(false) do |cursor, _parent|
        case cursor.kind
        when :cursor_struct
          collect_struct(cursor) if box2d_declaration?(cursor)
        when :cursor_enum_decl
          collect_enum(cursor) if box2d_declaration?(cursor)
        when :cursor_function
          collect_function(cursor) if api_names.include?(cursor.spelling)
        end
        :continue
      end
    end

    def collect_struct(cursor)
      fields = []
      cursor.each(false) do |field, _parent|
        next :continue unless field.kind == :cursor_field_decl

        fields << Field.new(
          name: field.spelling,
          type: @mapper.field(field.type),
          offset: field.offset_of_field / 8
        )
        :continue
      end
      return if fields.empty?

      @structs << Struct.new(
        name: cursor.spelling,
        ruby_name: ruby_name(cursor.spelling),
        size: cursor.type.sizeof,
        alignment: cursor.type.alignof,
        fields:
      )
    end

    def collect_enum(cursor)
      values = {}
      cursor.each(false) do |constant, _parent|
        next :continue unless constant.kind == :cursor_enum_constant_decl

        values[enum_constant_name(constant.spelling)] = constant.enum_value
        :continue
      end
      return if values.empty?

      @enums << Enum.new(
        name: cursor.spelling,
        ruby_name: ruby_name(cursor.spelling),
        values:
      )
    end

    def collect_function(cursor)
      arguments = cursor.type.arg_types.map { |type| @mapper.parameter(type) }
      @functions << Function.new(
        name: cursor.spelling,
        arguments:,
        result: @mapper.parameter(cursor.result_type)
      )
    end

    def box2d_declaration?(cursor)
      cursor.spelling.start_with?("b2") && cursor.location.file.to_s.start_with?(INCLUDE_ROOT)
    end

    def exported_function_names
      Dir[File.join(INCLUDE_ROOT, "box2d/*.h")].flat_map do |header|
        File.read(header).scan(/\bB2_API\s+[^;{]+?\b(b2[A-Za-z0-9_]+)\s*\(/m).flatten
      end.to_h { |name| [name, true] }
    end

    def render_bindings
      <<~RUBY
        # frozen_string_literal: true

        # Generated by generator/generate.rb from Box2D #{box2d_version} headers.
        # Do not edit this file directly.

        require "ffi"
        require_relative "native_loader"

        module Box2D
          module Native
            extend FFI::Library

            ffi_lib NativeLoader.library_path

        #{render_enums}
        #{render_structs}
            ABI_LAYOUTS = #{render_layout_hash}.freeze

        #{render_functions}
          end
        end
      RUBY
    end

    def render_enums
      @enums.map do |enum|
        constants = enum.values.map { |name, value| "      #{name} = #{value}" }.join("\n")
        <<~RUBY.chomp
              module #{enum.ruby_name}
        #{constants}
              end
        RUBY
      end.join("\n\n")
    end

    def render_structs
      @structs.map do |struct|
        fields = struct.fields.flat_map { |field| [":#{field.name}", field.type] }
        layout = fields.each_slice(2).map.with_index do |(name, type), index|
          suffix = index == (fields.length / 2) - 1 ? "" : ","
          "        #{name}, #{type}#{suffix}"
        end.join("\n")
        <<~RUBY.chomp
              class #{struct.ruby_name} < FFI::Struct
                layout(
        #{layout}
                )
              end
        RUBY
      end.join("\n\n")
    end

    def render_layout_hash
      lines = @structs.map do |struct|
        offsets = struct.fields.to_h { |field| [field.name.to_sym, field.offset] }
        "#{struct.ruby_name.inspect} => {size: #{struct.size}, alignment: #{struct.alignment}, offsets: #{offsets.inspect}}"
      end
      "{\n      #{lines.join(",\n      ")}\n    }"
    end

    def render_functions
      @functions.map do |function|
        options = function.name == "b2World_Step" ? ", blocking: true" : ""
        "    attach_function :#{function.name}, [#{function.arguments.join(", ")}], #{function.result}#{options}"
      end.join("\n")
    end

    def render_probe
      struct_lines = @structs.flat_map do |struct|
        [
          %(printf("S\\t#{struct.name}\\t%zu\\t%zu\\n", sizeof(#{struct.name}), _Alignof(#{struct.name}));),
          *struct.fields.map do |field|
            %(printf("F\\t#{struct.name}\\t#{field.name}\\t%zu\\n", offsetof(#{struct.name}, #{field.name}));)
          end
        ]
      end

      <<~C
        // Generated by generator/generate.rb. Do not edit.
        #include <stddef.h>
        #include <stdio.h>
        #include <box2d/box2d.h>

        int main(void)
        {
        #{struct_lines.map { |line| "    #{line}" }.join("\n")}
            return 0;
        }
      C
    end

    def write_or_check(path, content, check:)
      if check
        abort "#{path.delete_prefix("#{ROOT}/")} is out of date" unless File.file?(path) && File.read(path) == content
        return
      end

      File.write(path, content)
      puts "generated #{path.delete_prefix("#{ROOT}/")}"
    end

    def ruby_name(name)
      name.delete_prefix("b2")
    end

    def enum_constant_name(name)
      name
        .delete_prefix("b2_")
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .upcase
    end

    def box2d_version
      File.read(File.join(ROOT, "ext/box2d/vendor/box2d/VERSION")).strip
    end
  end
end

Box2DBindings::Generator.new.run(check: ARGV.delete("--check"))
