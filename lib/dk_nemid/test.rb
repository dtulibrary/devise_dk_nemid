class SavonObserver
  def logger
    Rails.logger
  end

  def notify(operation_name, builder, globals, locals)
    logger.info "Operation: "+operation_name.inspect
    logger.info "Builder: "+builder.inspect
    nil
  end
end
