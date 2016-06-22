module ProcedureGenerator
  def self.generate_checkin
    CheckinProcedure.create!(attributes)
  end

  def self.generate_checkout
    CheckoutProcedure.create!(attributes)
  end

  private

  def self.attributes
    { step: FFaker::HipsterIpsum.sentence,
      equipment_model_id: EquipmentModel.all.sample.id }
  end
end
