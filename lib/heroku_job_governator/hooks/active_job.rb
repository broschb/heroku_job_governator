module HerokuJobGovernator
  module Hooks
    module ActiveJob
      def self.included(base)
        base.class_eval do
          after_enqueue do |job|
            queue_name = queue(job)
            HerokuJobGovernator::Governor.instance.scale_up(
              queue_name,
              HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
            )
          end

          around_perform do |job, block|
            queue_name = queue(job)
            begin
              HerokuJobGovernator::Governor.instance.scale_up(
                queue_name,
                HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
              )
              block.call
            ensure
              HerokuJobGovernator::Governor.instance.scale_down(
                queue_name,
                HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
              )
            end
          end

          after_perform do |job|
            queue_name = queue(job)
            HerokuJobGovernator::Governor.instance.scale_down(
              queue_name,
              HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
            )
          end

          def queue(job)
            queue_name = job.queue_name
            queue_name = HerokuJobGovernator.config.default_queue if queue_name.to_sym == :default
            queue_name.to_sym
          end
        end
      end
    end
  end
end
