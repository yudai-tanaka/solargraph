# HACK Fix autoload issue
require 'solargraph/source/chain/link'

module Solargraph
  class Source
    class Chain
      autoload :Link,             'solargraph/source/chain/link'
      autoload :Call,             'solargraph/source/chain/call'
      autoload :Variable,         'solargraph/source/chain/variable'
      autoload :ClassVariable,    'solargraph/source/chain/class_variable'
      autoload :Constant,         'solargraph/source/chain/constant'
      autoload :InstanceVariable, 'solargraph/source/chain/instance_variable'
      autoload :GlobalVariable,   'solargraph/source/chain/global_variable'
      autoload :Literal,          'solargraph/source/chain/literal'
      autoload :Definition,       'solargraph/source/chain/definition'
      autoload :Head,             'solargraph/source/chain/head'

      UNDEFINED_CALL = Chain::Call.new('<undefined>')
      UNDEFINED_CONSTANT = Chain::Constant.new('<undefined>')

      # @return [Array<Source::Chain::Link>]
      attr_reader :links

      # @param links [Array<Chain::Link>]
      def initialize links
        @links = links
        @links.push UNDEFINED_CALL if @links.empty?
      end

      # @return [Chain]
      def base
        @base ||= Chain.new(links[0..-2])
      end

      # @param api_map [ApiMap]
      # @param context [Context]
      # @param locals [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def define api_map, context, locals
        return [] if undefined?
        type = ComplexType::UNDEFINED
        head = true
        links[0..-2].each do |link|
          pins = link.resolve(api_map, context, head ? locals : [])
          head = false
          return [] if pins.empty?
          pins.each do |pin|
            type = pin.infer(api_map)
            break unless type.undefined?
          end
          return [] if type.undefined?
          context = type
        end
        links.last.resolve(api_map, context, head ? locals: [])
      end

      # @param api_map [ApiMap]
      # @param context [ComplexType]
      # @param locals [Array<Pin::Base>]
      # @return [ComplexType]
      def infer api_map, context, locals
        return ComplexType::UNDEFINED if undefined?
        type = ComplexType::UNDEFINED
        pins = define(api_map, context, locals)
        pins.each do |pin|
          type = pin.infer(api_map)
          break unless type.undefined?
        end
        type
      end

      def literal?
        links.last.is_a?(Chain::Literal)
      end

      def undefined?
        links.any?(&:undefined?)
      end

      def constant?
        links.last.is_a?(Chain::Constant)
      end
    end
  end
end