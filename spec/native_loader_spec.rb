# frozen_string_literal: true

RSpec.describe Box2D::NativeLoader do
  describe ".library_path" do
    it "finds the compiled extension" do
      expect(File.basename(described_class.library_path)).to eq(described_class::EXTENSION_NAME)
    end

    it "honors an explicit library path" do
      path = described_class.library_path

      begin
        ENV[described_class::ENVIRONMENT_KEY] = path
        expect(described_class.library_path).to eq(File.expand_path(path))
      ensure
        ENV.delete(described_class::ENVIRONMENT_KEY)
      end
    end

    it "rejects a missing explicit library path" do
      begin
        ENV[described_class::ENVIRONMENT_KEY] = "/missing/libbox2d"
        expect { described_class.library_path }.to raise_error(Box2D::LoadError, /does not point to a file/)
      ensure
        ENV.delete(described_class::ENVIRONMENT_KEY)
      end
    end
  end
end
