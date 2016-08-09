# frozen_string_literal: true
require Rails.root.join('spec/support/mockers/mocker.rb')
require Rails.root.join('spec/support/mockers/category.rb')

class EquipmentModelMock < Mocker
  def self.klass
    EquipmentModel
  end

  def self.klass_name
    'EquipmentModel'
  end

  private

  def with_category(cat: nil)
    cat ||= CategoryMock.new
    child_of_has_many(mocked_parent: cat, parent_sym: :category,
                      child_sym: :equipment_models)
  end
end
