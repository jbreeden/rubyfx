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


# This file provides the "WebClientHub" and "WebServerHub" classes.
# These classes 


module RubyFx
  
  # Called to create a pair of web hubs, allowing simple asynchronous
  # communication between a JRuby "server" object and the JavaScript in a WebView.
  # The method accepts
  # - server: The Ruby object to which all events from the WebClientHub will be dispatched (as method calls)
  # - web_view: The WebView to inject the WebClientHub into
  # - hub_name: The name of the global object in the JavaScript context to which method calls from the WebServerHub
  #             will be dispatched. This object will also receive a field, `hub_name.server` on which the client triggers
  #             events, ex: `hub_name.server.emit('event_name', {event: 'argument_object'})`
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
  
  # Simple LoadListener to detect when a browser has loaded.
  # This is used to ensure the WebClientHub is injected into the WebView
  # after the page has loaded. That way, the client has an opportunity to 
  # configure the hub receiver before we attempt to bind to it.
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

  # become_java! helps java recognize the `changed` method definition
  LoadListener.become_java!
  
  # Used by JRuby code to talk to the JavaScript in a WebView.
  # This class has no real methods. Instead, method_missing forwards
  # all method calls on this object to the client's receiver hub.
  # A method call may have 0 or 1 arguments, which must be either a
  # hash or an array (i.e., serializable into a valid JSON object)
  class WebServerHub
    def initialize(js_object)
      @js_object = js_object
    end
    
    def method_missing(name, *args, &block)
      if args[0].nil?
        argument = ""
      else
        argument = "JSON.parse('#{args[0].to_json}')"
      end
      
      js = (<<-JS)
        if (typeof this.#{name} === 'function'){
          this.#{name}(#{argument});
        }
      JS
      @js_object.eval js
    end
  end

  # Used by the JavaScript within a WebView to talk to JRuby code.
  class WebClientHub
    def initialize(server_object)
      @server_object = server_object
    end

    java_signature "void emit(java.lang.String, netscape.javascript.JSObject)"
    def emit(event, js_object)
      return unless @server_object.respond_to? event.to_sym
      json = js_object.eval(<<-JS)
        JSON.stringify(this);
      JS
      @server_object.method(event.to_sym)[JSON.parse(json)]
      return nil
    end
  end

  # become_java! helps the WebView locate methods correctly
  WebClientHub.become_java!
end