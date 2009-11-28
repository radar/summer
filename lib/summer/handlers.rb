module Summer
  module Handlers
    def handle_422(message)
      self.ready = true
    end
    
    alias_method :handle_376, :handle_422
    
  end
end