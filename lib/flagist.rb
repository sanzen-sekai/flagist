require "flagist/version"

module Flagist
  class UnknownFlagError < ::StandardError
    def self.raise_by(method,prop,value)
      raise ::Flagist::UnknownFlagError, "#{method}'s #{prop} not exists. value: [#{value.inspect}]"
    end
  end

  module ClassMethods
    def install(m)
      included(m)
    end

    def configure
      @config ||= OpenStruct.new
      yield @config if block_given?
      @config
    end
    def config
      @config
    end
  end
  extend ClassMethods

  configure do |config|
    config.i18n_namespace = "activerecord.flagist"
  end


  def self.included(m)
    m.extend ::Flagist::ModuleMethods
  end

  module ModuleMethods
    def flagist
      flagist = @flagist ||= {}
      if block_given?
        yield ::Flagist::Definer.new(self,flagist)

        self.class.class_eval do
          flagist.each do |method,info|
            {value: "", name: "_name", label: "_label"}.each do |prop,suffix|
              define_method :"#{method}#{suffix}" do |args|
                if args.respond_to?(:map)
                  args_is_array = true
                  wrapped_args = args
                else
                  wrapped_args = [args]
                end

                result = wrapped_args.map{|arg|
                  value, flag = flagist[method][:flags].find{|value,flag|
                    value == arg ||
                      flag[:name] == arg ||
                      (arg.respond_to?(:to_sym) && flag[:name] == arg.to_sym) ||
                      flag[:label] == arg
                  }
                  unless flag
                    ::Flagist::UnknownFlagError.raise_by method, "value", arg
                  end
                  flag[prop]
                }

                if args_is_array
                  result
                else
                  result.first
                end
              end
            end
            %i(name label).each do |prop|
              define_method :"#{method}_#{prop}s" do
                flagist[method][:flags].each.map{|value,flag| [value,flag[prop]]}.to_h
              end
              define_method :"#{method}_#{prop}s_inverse" do
                flagist[method][:flags].each.map{|value,flag| [flag[prop],value]}.to_h
              end
            end
          end
        end

        instance_methods = Module.new
        instance_methods.class_eval do
          flagist.each do |method,info|
            {value: "", name: "_name", label: "_label"}.each do |prop,suffix|
              define_method :"#{method}#{suffix}" do |*all_args|
                if all_args.size > 1
                  raise ::ArgumentError, "wrong number of arguments (given #{all_args.size}, expected 0..1)"
                end

                if all_args.size > 0
                  args = all_args.first
                else
                  if prop == :value
                    return super()
                  end

                  args = __send__ method

                  if info[:type] == :array
                    if args.respond_to?(:split)
                      args = args.split(",")
                    end
                  end
                end

                self.class.__send__(:"#{method}#{suffix}", args).freeze
              end
            end
            %i(name label).each do |prop|
              ["","_inverse"].each do |suffix|
                define_method :"#{method}_#{prop}s#{suffix}" do
                  self.class.__send__ :"#{method}_#{prop}s#{suffix}"
                end
              end
              define_method :"#{method}_#{prop}=" do |new_values|
                if info[:type] != :array
                  new_values = [new_values]
                end

                result = new_values.map{|new_value|
                  value, flag = flagist[method][:flags].find{|value,flag| flag[prop] == new_value}
                  unless flag
                    ::Flagist::UnknownFlagError.raise_by method, prop, new_value
                  end
                  value
                }

                if info[:type] == :array
                  result = result.join(",")
                else
                  result = result.first
                end
                __send__ :"#{method}=", result
              end
            end
          end
        end
        self.__send__ :prepend, instance_methods
      end
      flagist
    end
  end

  class Definer < ::BasicObject
    def initialize(model,data)
      @config = ::Flagist.config
      @model = model
      @data = data
    end

    def method_missing(method,*args)
      if args.size > 1
        case args.first
        when ::Hash
          opts = args.shift
        end
      end
      case args.last
      when ::Hash
        hash = args.pop
      end

      info = @data[method] ||= {}
      if opts
        opts.each do |k,v|
          info[k] = v
        end
      end

      unless info[:type]
        info[:type] = (method.to_s.pluralize == method.to_s) ? :array : :scalar
      end

      flags = info[:flags] ||= {}

      args.each do |value|
        flag = flags[value] ||= {}
        flag[:value] = value
        flag[:name] = value
      end

      if hash
        hash.each do |value,name|
          flag = flags[value] ||= {}
          flag[:value] = value
          flag[:name] = name
        end
      end

      labels = ::I18n.translate("#{@config.i18n_namespace}.#{@model.model_name.singular}.#{method}", default: {})
      flags.each do |value,flag|
        name = flag[:name]
        if labels[name]
          flag[:label] = labels[name]
        end
      end

      info
    end
  end
end
