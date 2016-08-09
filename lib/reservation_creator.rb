class ReservationCreator
  # Service Object to create reservations in the reservations controller
  def initialize(cart:, current_user:, override: false, notes: '')
    @current_user = current_user
    @cart = cart
    @cart_errors = cart.validate_all
    @override = override
    @notes = notes
  end

  def create!
    return { result: nil, error: error } if error
    reservation_transaction
  end

  def request?
    !override && !cart_errors.blank? 
  end

  private

  attr_reader :cart, :current_user, :override, :notes, :cart_errors

  def error
    return 'requests disabled' if request? && AppConfig.check(:disable_requests)
    return 'needs notes' if (request? && !valid_request?) || 
                              (override? && !valid_override?)
  end

  def valid_request?
    request? && !notes.blank?
  end

  def override?
    override && !cart_errors.blank? 
  end

  def valid_override?
    override? && !notes.blank?
  end

  def reservation_transaction
    Reservation.transaction do
      begin
        create_method = request? ? :request_all : :reserve_all
        return { result: cart.send(create_method, current_user, notes),
                 error: nil }
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        raise ActiveRecord::Rollback
        return { result: nil, error: e.message }
      end
    end
  end
end
