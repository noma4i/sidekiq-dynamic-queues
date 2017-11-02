require 'sidekiq/fetch'

module Sidekiq
  module DynamicQueues

    # enable with:
    #    Sidekiq.configure_server do |config|
    #        config.options[:fetch] = Sidekiq::DynamicQueues::Fetch
    #    end
    #
    class Fetch < Sidekiq::BasicFetch

      include Sidekiq::Util
      include Sidekiq::DynamicQueues::Attributes

      def initialize(options)
        super
        @dynamic_queues = self.class.translate_from_cli(*options[:queues])
      end

      # overriding Sidekiq::BasicFetch#queues_cmd
      def queues_cmd
        if @dynamic_queues.grep(/(^!)|(^@)|(\*)/).size == 0
          super
        else
          queues = expand_queues(@dynamic_queues)
          queues = queues.shuffle if !@strictly_ordered_queues
          queues << 'default' if queues.empty?
          queues = queues.uniq.map { |q| "queue:#{q}" }
          queues << TIMEOUT
        end
      end

      def self.translate_from_cli(*queues)
        queues.collect do |queue|
          queue.gsub('.star.', '*').gsub('.at.', '@').gsub('.not.', '!')
        end
      end

    end

  end
end
