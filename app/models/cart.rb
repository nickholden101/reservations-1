class Cart
  include ActiveModel::Validations
  extend ActiveModel::Naming
  
  validates :reserver_id, :start_date, :due_date, :presence => true
  validate :reserver_valid?, :logical_start_and_due_dates?, 
           :too_many_of_category?, :too_many_of_equipment_model?,
           :duration_too_long?
  
  attr_accessor :reserver_id, :items, :start_date, :due_date
  attr_reader   :errors
  
  def initialize
    @errors = ActiveModel::Errors.new(self)
    @items = []
    @start_date = Date.today
    @due_date = Date.today
  end
  
  def persisted?
    false
  end
  
  ## functions for error handling
  
  def read_attribute_for_validation(attr)
    send(attr)
  end

  def Cart.human_attribute_name(attr, options = {})
    attr
  end

  def Cart.lookup_ancestors
    [self]
  end

  ## end of functions for error handling

  def add_equipment_model(equipment_model)
    current_item = @items.find {|item| item.equipment_model == equipment_model}
    if current_item
      current_item.increment_quantity
    else
      current_item = CartItem.new(equipment_model)
      @items << current_item
    end
    if self.valid?
    end
    current_item
  end

  def remove_equipment_model(equipment_model)
    current_item = @items.find {|item| item.equipment_model == equipment_model}
    current_item.decrement_quantity
    if current_item.quantity == 0
      @items.delete(current_item)
    end
    current_item
  end

  def get_cart_items
    items = []
    @items.each do |item|
      items << item.details
    end
    items
  end

  def total_items
    @items.sum{ |item| item.quantity }
  end

  def empty?
    @items.empty?
  end

  def available?
    return false if start_date.nil? or due_date.nil?
    @items.each do |item|
      return false if !item.available?(start_date..due_date)
    end
    return true
  end

  def set_start_date(date)
    @start_date = date
  end

  def set_due_date(date)
    @due_date = date
  end
  
  def set_reserver_id(user_id)
    @reserver_id = user_id
  end
  
  def duration #in days
    @due_date - @start_date + 1
  end
  
  ## Validations
  
  def logical_start_and_due_dates?
    unless @due_date >= @start_date && @start_date >= Date.today
      errors.add(:base,"Dates are not logical")
      return false
    end
    return true
  end
  
  #Check if the reserver exists and is a valid user
  def reserver_valid?
    user = User.find(@reserver_id)
    unless !user.nil? && user.valid?
      errors.add(:reserver_id,"Reserver_id points to an invalid User")
      return false
    end
    return true
  end
  
  #Check if the user exceeds the maximum number of any equipment models 
  def too_many_of_equipment_model?
    user = User.find(@reserver_id)
    user_model_counts = user.checked_out_models
    @items.each do |item|
      eq_model = item.equipment_model
      curr_model_count = user_model_counts[eq_model.id]
      
      # This thing with unrestricted makes me upset
      if eq_model.maximum_per_user != "unrestricted"
        unless eq_model.maximum_per_user >= item.quantity + curr_model_count
          errors.add(:items, user.name + " has too many of " + eq_model.name)
          return false
        end
      end
    end
    return true
  end
  
  #Check if the user exceeds the maximum number of any equipment models 
  def too_many_of_category?
    user = User.find(@reserver_id)
    h = user.checked_out_models
    
    #Make an array of the equipment models for the user and their respective categories
    eq_model_and_cats = EquipmentModel.find(h.keys).collect {|model| [model.id, model.category_id]}
    catHash = Hash[*eq_model_and_cats.flatten]
    #Make sure the keys align with the equipment models
    catArr = h.keys.collect {|i| catHash[i]}
    user_categories = catArr.uniq
    
    #Collect a count of the number of objects a user has in a category
    user_category_counts = user_categories.collect do |category|
      inCat = catHash.rassoc(category)
      inCat.inject(0) {|sum,k| sum + h[k]}
    end
    user_category_counts = Hash[*user_categories.zip(user_category_counts).flatten]
    
    #Test each of the categories to see if the user exceeds the limit
    user_categories.each do |category_id|
      curr_cat_count = user_category_counts[category_id]
      curr_cat = Category.find(category_id)
      if curr_cat.maximum_per_user != "unrestricted"
        unless curr_cat.maximum_per_user >= item.quantity + curr_cat_count
          errors.add(:items, user.name + " has too many of " + curr_cat.name)
          return false
        end
      end
    end
  end
  
  # Check if the duration is longer than the maximum checkout length for any of the item
  def duration_too_long?
    @items.each do |item|
      eq_model = item.equipment_model
      category = eq_model.category
      binding.pry
      unless !category.max_checkout_length.nil? && self.duration <= category.max_checkout_length
        errors.add(:items, "You can only check out " + eq_model.name + " for " + category.max_checkout_length.to_s + " days")
        return false
      end
    end
    return true
  end
end

