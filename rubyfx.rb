require 'java'

module RubyFx
  def self.launch(&callback)
    ApplicationAdapter.set_on_start { |stage|
      callback[stage]
    }
    applicationClass = java.lang.Class.forName('com.github.crossfx.ApplicationAdapter')
    Application.launch(applicationClass, [].to_java(:string))
  end

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
      file = JFile.new(path)
      fxml_url = file.toURI.toURL
      self.fxml_loader = CrossFxmlLoader.new(fxml_url)
      self.fxml_loader.controller = controller_adapter
      @scene = RubyFx::Scene.new(self.fxml_loader.load)
    end

    # Must be called after `fxml=`
    def stage=(stage)
      @stage = stage
      @stage.scene = @scene
    end

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

    def to_controller_adapter
      controller_adapter = ControllerAdapter.new

      controller_adapter.on_set_fxml_loader do |fxml_loader|
        self.fxml_loader = fxml_loader
      end
      
      # JavaFX expects the method to be called "initialize", but this has
      # special meaning in Ruby, so we call ours "initialize_callack" and
      # simply rename it as we put it into the ControllerAdapter
      controller_adapter.add_method 'initialize', self.method(:initialize_callback)
      
      possibly_event_handling_methods.each do |method_name|
        puts "Adding method '#{method_name}' to controller adapter"
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
          puts "Adding nested controller: #{var}"
          controller_adapter.add_nested_controller(
            var[1, var.length],
            val.send(:to_controller_adapter)
          )
        end
      end

      controller_adapter
    end
    
    private
    
    def possibly_event_handling_methods
      methods = class << self; instance_methods(false); end
      self.class.ancestors.reject { |a| 
        a == ::RubyFx::Controller || a == Kernel || a == Object || a == BasicObject 
      }.each do |a|
        methods += a.instance_methods(false)
      end
      methods
    end
    
  end

  # Chooser Helpers
  # ---------------

  def self.choose_directory(title="Choose Directory")
    stage = RubyFx::Stage.new
    chooser = RubyFx::DirectoryChooser.new
    stage.title = title
    chooser.showDialog(stage)
  end

  # Imports
  # -------

  ApplicationAdapter = com.github.crossfx.ApplicationAdapter
  CrossFxmlLoader = com.github.crossfx.CrossFxmlLoader
  ControllerAdapter = com.github.crossfx.ControllerAdapter
  JFile =  java.io.File

  include_package 'javafx.animation'
  include_package 'javafx.application'
  include_package 'javafx.beans'
  include_package 'javafx.beans.binding'
  include_package 'javafx.beans.property'
  include_package 'javafx.beans.property.adapter'
  include_package 'javafx.beans.value'
  include_package 'javafx.collections'
  include_package 'javafx.concurrent'
  include_package 'javafx.embed.swing'
  include_package 'javafx.embed.swt'
  include_package 'javafx.event'
  include_package 'javafx.fxml'
  include_package 'javafx.geometry'
  include_package 'javafx.scene'
  include_package 'javafx.scene.canvas'
  include_package 'javafx.scene.chart'
  include_package 'javafx.scene.control'
  include_package 'javafx.scene.control.cell'
  include_package 'javafx.scene.effect'
  include_package 'javafx.scene.image'
  include_package 'javafx.scene.input'
  include_package 'javafx.scene.layout'
  include_package 'javafx.scene.media'
  include_package 'javafx.scene.paint'
  include_package 'javafx.scene.shape'
  include_package 'javafx.scene.text'
  include_package 'javafx.scene.transform'
  include_package 'javafx.scene.web'
  include_package 'javafx.stage'
  include_package 'javafx.util'
  include_package 'javafx.util.converter'
  include_package 'netscape.javascript'
end