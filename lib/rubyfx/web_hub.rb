module RubyFx
  def self.web_hub(server, web_view, hub_name='hub', &block)
    state_property = web_view.engine.load_worker.state_property
    state_property.addListener( LoadListener.new do |new_value|
      if new_value == RubyFx::Worker::State::SUCCEEDED
        hub = web_view.engine.execute_script("window.#{hub_name}");
        client_hub = WebClientHub.new(server)
        hub.setMember('server', client_hub)
        block[WebServerHub.new(web_view.engine.execute_script(hub_name))]
      end
    end)
  end
  
  class LoadListener
    include RubyFx::ChangeListener
    
    def initialize &block
      @callback = block
    end
    
    java_signature 'void changed(javafx.beans.value.ObservableValue, java.lang.Object, java.lang.Object)'
    def changed(observable, old_value, new_value)
      @callback[new_value]
    end
  end
  LoadListener.become_java!
  
  # Used by JRuby code to talk to the JavaScript in a WebView
  class WebServerHub
    def initialize(js_object)
      @js_object = js_object
    end

    def method_missing(name, *args, &block)
      argument = args[0].to_json
      @js_object.eval(<<-JS)
        if (typeof this.#{name} === 'function'){
          this.#{name}(JSON.parse('#{argument}'));
        }
      JS
    end
  end

  # Used by the JavaScript within a WebView to talk to JRuby code
  class WebClientHub
    def initialize(server_object)
      @server_object = server_object
    end

    java_signature "void emit(java.lang.String, netscape.javascript.JSObject)"
    def emit(event, js_object)
      return unless @server_object.respond_to? event.to_sym
      # JSObject --stringify--> String --parse--> Ruby
      json = js_object.eval(<<-JS)
        JSON.stringify(this);
      JS
      @server_object.method(event.to_sym)[JSON.parse(json)]
      return nil
    end
  end

  # become_java! helps the js in the WebView locate its methods correctly
  WebClientHub.become_java!
end