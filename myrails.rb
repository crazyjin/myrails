#encoding utf-8
require 'rubygems'
require 'bundler/setup'
require 'slim'

module MyRails
  class Router
    @@routes = {}
    class << self
      #RSTfull route helpers, simply map path to controllers and actions
      #get "/blogs", "blogs_controller#index"
      #post "/blogs", "blogs_controller#create"
      %i{get post put delete}.each do |m|
        define_method(m) do |path, action| 
          controller, action = action.split('#')
          controller = controller.split('_').collect(&:capitalize).join
          controller = Object.const_get controller

          @@routes[m] = {} if @@routes[m].nil?
          @@routes[m][path] = [controller, action.to_sym]
        end
      end

      def draw_routes(&block)
        self.instance_eval(&block)
      end

      def call_controller_action env
        method, path, params = env['REQUEST_METHOD'].downcase.to_sym, env["REQUEST_PATH"], env["QUERY_STRING"]
        return [404, {"content-type" => "text/html"}, ["404, you got it!!"]] if @@routes[method].nil? || @@routes[method][path].nil?

        controller = @@routes[method][path][0].new(params)
        action = @@routes[method][path][1]
        controller.send action

        [controller.http_status, controller.http_headers, [controller.http_body]]
      rescue
        [500, {"content-type" => "text/html"}, [$!.message]]
      end
    end
  end

  class Controller
    attr_accessor :http_status, :http_headers, :http_body, :params

    class ViewContext 
      def create_accessable_instance_variable key
        singleton_class.class_eval {attr_accessor key}
      end
    end

    def initialize query_string=""
      key_value_strs =  query_string.split('&')
      key_value_strs.each do |str|
        key_value_pair = str.split '='
        @params[key_value_pair[0]] = key_value_pair[1] if 2 <= key_value_pair.length
      end

      @http_status = 200
      @http_headers = {"content-type" => "text/html"}
    end

    def render template
      layout = File.open("./application.html.slim", "rb").read
      content = File.open("./#{template.to_s}.html.slim", "rb").read
      
      l = Slim::Template.new { layout }

      variables = instance_variables
      env = ViewContext.new
      variables.each do |v|
        env.create_accessable_instance_variable v[1..-1]
        env.send("#{v[1..-1]}=", instance_variable_get(v))
      end

      c = Slim::Template.new { content }.render(env)
      @http_body = l.render { c }
    end
  end

  class Application
    class << self
      def draw_routes &b
        Router.draw_routes &b
      end

      #rack server need this
      def call(env)
        Router.call_controller_action env
      rescue
        $!.backtrace.each {|l| puts l }
      end
    end
  end
end
