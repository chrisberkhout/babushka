require 'spec_helper'

describe Renderable do
  subject { Renderable.new(tmp_prefix / 'example.conf') }
  it "should not exist" do
    subject.exists?.should be_false
  end
  describe '#render' do
    before { subject.render('spec/renderable/example.conf.erb') }
    it "should exist" do
      subject.exists?.should be_true
    end
    it "should have added the prefix" do
      (tmp_prefix / 'example.conf').read.should =~ Renderable::SEAL_REGEXP
    end
    it "should have interpolated the erb" do
      (tmp_prefix / 'example.conf').read.should =~ /root #{tmp_prefix};/
    end
    describe "#clean?" do
      it "should be clean" do
        subject.should be_clean
      end
      context "after shitting up the file" do
        before {
          shell "echo lulz >> #{subject.path}"
        }
        it "should not be clean" do
          subject.should_not be_clean
        end
      end
    end
    describe '#from?' do
      it "should be from the same content" do
        subject.should be_from('spec/renderable/example.conf.erb')
      end
      it "should not be from different content" do
        subject.should_not be_from('spec/renderable/different_example.conf.erb')
      end
    end
  end
  describe "binding handling" do
    context "when no explicit binding is passed" do
      before {
        subject.instance_eval {
          def custom_renderable_path
            "from implicit binding"
          end
        }
        subject.render('spec/renderable/with_binding.conf.erb')
      }
      it "should render using the implicit binding" do
        (tmp_prefix / 'example.conf').read.should =~ /from implicit binding/
      end
    end
    context "when an explicit binding is passed" do
      before {
        dep 'renderable binding spec' do
          def custom_renderable_path
            "from explicit binding"
          end
        end
        subject.render('spec/renderable/with_binding.conf.erb', :context => Dep('renderable binding spec').context)
      }
      it "should render using the given binding" do
        (tmp_prefix / 'example.conf').read.should =~ /from explicit binding/
      end
    end
  end
end
