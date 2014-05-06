# The MIT License (MIT)
#
# Copyright (c) 2014 Jared Breeden
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module RubyFx
  class Controller
    attr_accessor :fxml_loader
    attr_reader :stage
    alias_method :fxmlLoader, :fxml_loader
    alias_method :fxmlLoader=, :fxml_loader=

    def initialize(&block)
      @event_handlers = {}
      if block
        self.instance_eval &block
      end
    end

    # Must be called before `stage=`
    def fxml=(path)
      controller_adapter = to_controller_adapter
      file = java.io.File.new(path)
      fxml_url = file.toURI.toURL
      self.fxml_loader = SplatFxmlLoader.new(fxml_url)
      self.fxml_loader.controller = controller_adapter
      @scene = RubyFx::Scene.new(self.fxml_loader.load)
    end

    # Must be called after `fxml=`
    def stage=(stage)
      @stage = stage
      @stage.scene = @scene
    end

    # Callback invoked by the FXML loader when it has finished loading FXML.
    # This method fetches all objects in the FXML namepace and assigns them as
    # instance variables on the controller object (self). This allows dynamic
    # field creation for any FXML elements with an fx:id attribute.
    def initialize_callback(arg)
      namespace = self.fxml_loader.namespace
      keySet = namespace.keySet.toArray
      keySet.each do |key|
        next if key == "controller"
        if instance_variable_defined? "@#{key}".to_sym
          puts "Warning: fxml namespace contains field named #{key}, " +
               "but instance variable @#{key} is already defined"
        end
        instance_variable_set "@#{key}".to_sym, namespace.get(key)
      end
    end

    # Converts the control it is called on into a form suitable for FXML
    # loading & binding by the splatfx FXML loader.
    def to_controller_adapter
      controller_adapter = ControllerAdapter.new

      controller_adapter.on_set_fxml_loader do |fxml_loader|
        self.fxml_loader = fxml_loader
      end
      
      # JavaFX expects the method to be called "initialize", but this has
      # special meaning in Ruby, so we call ours "initialize_callack" and
      # simply rename it as we put it into the ControllerAdapter
      controller_adapter.add_method 'initialize', self.method(:initialize_callback)
      
      possible_event_handling_methods.each do |method_name|
        handler = self.method(method_name)
        if handler.arity == 0
          controller_adapter.add_method method_name do |event|
            handler[]
          end
        elsif handler.arity == 1
          controller_adapter.add_method method_name do |event|
            handler[event]
          end
        else
          controller_adapter.add_method method_name do |event|
            handler[event, *Array.new(handler.arity - 1, nil)]
          end
        end
      end

      self.instance_variables.each do |var|
        val = self.instance_variable_get(var)
        if val.kind_of? ::RubyFx::Controller
          controller_adapter.add_nested_controller(
            var[1, var.length],
            val.send(:to_controller_adapter)
          )
        end
      end

      controller_adapter
    end
    
    private
    
    # Gathers any methods on the controller that may be event handlers.
    # That includes any methods not defined on RubyFx::Controller, Kernel, Object, or BasicObject.
    # Put simply, only methods defined by the client to this library on the controller object.
    def possible_event_handling_methods
      methods = class << self; instance_methods(false); end
      self.class.ancestors.reject { |a| 
        a == ::RubyFx::Controller || a == Kernel || a == Object || a == BasicObject 
      }.each do |a|
        methods += a.instance_methods(false)
      end
      methods
    end
    
  end
end