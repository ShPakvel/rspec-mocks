require "spec_helper"
require "pp"

RSpec.describe "Diffs printed when arguments don't match" do
  before do
    allow(RSpec::Mocks.configuration).to receive(:color?).and_return(false)
  end

  context "with a non matcher object" do
    it "does not print a diff when single line arguments are mismatched" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with("some string")
        expect {
          d.foo("this other string")
        }.to fail_with(a_string_excluding("Diff:"))
      end
    end

    it "prints a diff of the strings for individual mismatched multi-line string arguments" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with("some string\nline2")
        expect {
          d.foo("this other string")
        }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n  expected: (\"some string\\nline2\")\n       got: (\"this other string\")\nDiff:\n@@ -1,3 +1,2 @@\n-some string\n-line2\n+this other string\n")
      end
    end

    it "prints a diff of the args lists for multiple mismatched string arguments" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with("some string\nline2", "some other string")
        expect {
          d.foo("this other string")
        }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n  expected: (\"some string\\nline2\", \"some other string\")\n       got: (\"this other string\")\nDiff:\n@@ -1,3 +1,2 @@\n-some string\\nline2\n-some other string\n+this other string\n")
      end
    end

    it "does not print a diff when multiple single-line string arguments are mismatched" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with("some string", "some other string")
        expect {
          d.foo("this other string", "a fourth string")
        }.to fail_with(a_string_excluding("Diff:"))
      end
    end

    let(:expected_hash) { {:foo => :bar, :baz => :quz} }

    let(:actual_hash) { {:bad => :hash} }

    it "prints a diff with hash args" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with(expected_hash)
        expect {
          d.foo(:bad => :hash)
        }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n  expected: (#{expected_hash.inspect})\n       got: (#{actual_hash.inspect})\nDiff:\n@@ -1,2 +1,2 @@\n-[#{expected_hash.inspect}]\n+[#{actual_hash.inspect}]\n")
      end
    end

    it "prints a diff with an expected hash arg and a non-hash actual arg" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with(expected_hash)
        expect {
          d.foo(Object.new)
        }.to fail_with(/-\[#{Regexp.escape(expected_hash.inspect)}\].*\+\[#<Object.*>\]/m)
      end
    end

    it "prints a diff with array args" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with([:a, :b, :c])
        expect {
          d.foo([])
        }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n  expected: ([:a, :b, :c])\n       got: ([])\nDiff:\n@@ -1,2 +1,2 @@\n-[[:a, :b, :c]]\n+[[]]\n")
      end
    end

    context "that defines #description" do
      it "does not use the object's description for a non-matcher object that implements #description" do
        with_unfulfilled_double do |d|

          collab = double(:collab, :description => "This string")
          collab_inspect = collab.inspect

          expect(d).to receive(:foo).with(collab)
          expect {
            d.foo([])
          }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n  expected: (#{collab_inspect})\n       got: ([])\nDiff:\n@@ -1,2 +1,2 @@\n-[#{collab_inspect}]\n+[[]]\n")
        end
      end
    end
  end

  context "with a matcher object" do
    context "that defines #description" do
      it "uses the object's description" do
        with_unfulfilled_double do |d|

          collab = fake_matcher(Object.new)
          collab_description = collab.description

          expect(d).to receive(:foo).with(collab)
          expect {
            d.foo([:a, :b])
          }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n  expected: (#{collab_description})\n       got: ([:a, :b])\nDiff:\n@@ -1,2 +1,2 @@\n-[\"#{collab_description}\"]\n+[[:a, :b]]\n")
        end
      end
    end

    context "that does not define #description" do
      it "for a matcher object that does not implement #description" do
        with_unfulfilled_double do |d|
          collab = Class.new do
            def self.name
              "RSpec::Mocks::ArgumentMatchers::"
            end
          end.new

          expect(RSpec::Support.is_a_matcher?(collab)).to be true

          collab_inspect = collab.inspect
          collab_pp = PP.pp(collab, "").strip

          expect(d).to receive(:foo).with(collab)
          expect {
            d.foo([:a, :b])
          }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n  expected: (#{collab_inspect})\n       got: ([:a, :b])\nDiff:\n@@ -1,2 +1,2 @@\n-[#{collab_pp}]\n+[[:a, :b]]\n")
        end
      end
    end
  end
end
