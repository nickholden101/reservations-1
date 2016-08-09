# frozen_string_literal: true
require 'rspec/mocks/standalone'

class Mocker < RSpec::Mocks::InstanceVerifyingDouble
  include RSpec::Mocks

  FIND_METHODS = [:find, :find_by_id].freeze

  def initialize(traits: [], **attrs)
    # from RSpec::Mocks::ExampleMethods
    # combination of #declare_verifying_double and #declare_double
    ref = ObjectReference.for(self.class.klass_name)
    RSpec::Mocks.configuration.verifying_double_callbacks.each do |block|
      block.call(ref)
    end
    attrs ||= {}
    super(ref, attrs)
    as_null_object
    process_traits(traits)
  end

  def process_traits(traits)
    traits.each { |t| send(*t) }
  end

  private

  def spy
    self
  end

  # lets us use rspec-mock syntax in mockers
  def receive(method_name, &block)
    Matchers::Receive.new(method_name, block)
  end

  def allow(target)
    AllowanceTarget.new(target)
  end

  # Traits
  def findable
    id = FactoryGirl.generate(:unique_id)
    allow(spy).to receive(:id).and_return(id)
    FIND_METHODS.each do |_method|
      allow(self.class.klass).to receive(:find)
      allow(self.class.klass).to receive(:find).with(id).and_return(spy)
      allow(self.class.klass).to receive(:find).with(id.to_s).and_return(spy)
    end
  end

  # Generalized association stubs
  def child_of_has_many(mocked_parent:, parent_sym:, child_sym:)
    allow(spy).to receive(parent_sym).and_return(mocked_parent)
    children = if mocked_parent.send(child_sym).is_a? Array
                 mocked_parent.send(child_sym) << spy
               else
                 [spy]
               end
    allow(mocked_parent).to receive(child_sym).and_return(children)
  end

  def parent_has_many(mocked_children:, parent_sym:, child_sym:)
    if mocked_children.is_a? Array
      mocked_children.each do |child|
        allow(child).to receive(parent_sym).and_return(spy)
      end
    end
    allow(spy).to receive(child_sym).and_return(mocked_children)
  end
end
