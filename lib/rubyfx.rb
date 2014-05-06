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

require 'java'
require 'jruby/core_ext'
require 'json'
require_relative "#{File.dirname __FILE__}/splatfx.jar"

module RubyFx
  
  # Launch Method
  # -------------
  
  def self.launch(&callback)
    ApplicationAdapter.set_on_start do |stage|
      callback[stage]
    end
    Application.launch(com.github.splatfx.ApplicationAdapter.java_class, [].to_java(:string))
  end

  # Chooser Helpers
  # ---------------

  def self.choose_directory(title="Choose Directory")
    stage = RubyFx::Stage.new
    chooser = RubyFx::DirectoryChooser.new
    stage.title = title
    chooser.showDialog(stage)
  end
  
  def self.save_file(title="Save File")
    stage = RubyFx::Stage.new
    chooser = RubyFx::FileChooser.new
    chooser.title = title
    chooser.show_save_dialog stage
  end
  
  def self.open_file(title="Open File")
    stage = RubyFx::Stage.new
    chooser = RubyFx::FileChooser.new
    chooser.title = title
    chooser.show_open_dialog stage
  end

  # Imports
  # -------

  ApplicationAdapter = com.github.splatfx.ApplicationAdapter
  SplatFxmlLoader = com.github.splatfx.SplatFxmlLoader
  ControllerAdapter = com.github.splatfx.ControllerAdapter

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

require_relative 'rubyfx/controller'
require_relative 'rubyfx/web_hub'