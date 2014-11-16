class EquipmentObject < ActiveRecord::Base

  include Searchable
  include Routing

  has_paper_trail

  belongs_to :equipment_model
  has_one :category, through: :equipment_model
  has_many :reservations

  validates :name,
            :equipment_model, presence: true

  nilify_blanks only: [:deleted_at]

  # table_name is needed to resolve ambiguity for certain queries with 'includes'
  scope :active, lambda { where("#{table_name}.deleted_at is null") }

  searchable_on(:name, :serial)

  def status
    if self.deleted? and self.deactivation_reason
      "Deactivated (#{self.deactivation_reason})"
    elsif self.deleted?
      "Deactivated"
    elsif r = self.current_reservation
      "checked out by #{r.reserver.name} through #{r.due_date.strftime("%b %d")}"
    else
      "available"
    end
  end

  def current_reservation
    return self.reservations.checked_out.first
  end

  def available?
    status == "available"
  end

  def self.for_eq_model(model_id,source_objects)
    # count the number of equipment objects for a given
    # model out of an array of source objects
    # 0 queries

    count = 0
    source_objects.each do |o|
      count += 1 if o.equipment_model_id == model_id
    end
    count
  end

  def make_reservation_notes(procedure_verb, reservation, handler, new_notes, time)
    new_str = "#### [#{procedure_verb.capitalize}](#{reservation_path(reservation.id)}) by #{handler.md_link} for #{reservation.reserver.md_link} on #{time.to_s(:long)}\n"
    unless new_notes.empty?
      new_str += "##### Notes:\n#{new_notes}\n\n"
    else
      new_str += "\n"
    end
    new_str += self.notes
    self.update_attributes(notes: new_str)
  end

  def make_switch_notes(old_res, new_res, handler)
    # set text depending on whether or not reservations are passed in
    old_res_msg = old_res ? old_res.md_link : 'available'
    new_res_msg = new_res ? new_res.md_link : 'available'
    self.update_attributes(notes: "#### Switched by #{handler.md_link} from #{old_res_msg} to #{new_res_msg} on #{Time.current.to_s(:long)}\n\n" + self.notes)
  end

  def update(current_user, new_params)
    self.assign_attributes(new_params)
    changes = self.changes
    if changes.empty?
      self
      return
    else
      new_notes = "#### Edited at #{Time.current.to_s(:long)} by #{current_user.md_link}\n\n"
      new_notes += "\n\n#### Changes:"
      changes.each do |param, diff|
        case param
        when 'name'
          name = 'Name'
          old_val = diff[0].to_s
          new_val = diff[1].to_s
        when 'serial'
          name = 'Serial'
          old_val = diff[0].to_s
          new_val = diff[1].to_s
        when 'equipment_model_id'
          name = 'Equipment Model'
          old_val = diff[0] ? EquipmentModel.find(diff[0]).name : 'nil'
          new_val = diff[1] ? EquipmentModel.find(diff[1]).name : 'nil'
        end
        new_notes += "\n#{name} changed from " + old_val + " to " + new_val + "." if (old_val && new_val)
      end
    end
    new_notes += "\n\n" + self.notes
    self.notes = new_notes.strip
    self
  end

  def md_link
    "[#{self.name}](#{equipment_object_url(self, only_path: false)})"
  end
end
