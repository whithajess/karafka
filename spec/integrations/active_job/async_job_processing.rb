# frozen_string_literal: true

# Karafka should be able to dispatch jobs using async adapter

setup_karafka
setup_active_job

Karafka::App.routes.draw do
  consumer_group DataCollector.consumer_group do
    active_job_topic DataCollector.topic
  end
end

class Job < ActiveJob::Base
  queue_as DataCollector.topic

  karafka_options(
    dispatch_method: :produce_async
  )

  def perform(value1, value2)
    DataCollector.data[0] << value1
    DataCollector.data[0] << value2
  end
end

VALUE1 = rand
VALUE2 = rand

Job.perform_later(VALUE1, VALUE2)

start_karafka_and_wait_until do
  DataCollector.data[0].size >= 1
end

aj_config = Karafka::App.config.internal.active_job

assert_equal aj_config.dispatcher.class, Karafka::ActiveJob::Dispatcher
assert_equal aj_config.job_options_contract.class, Karafka::ActiveJob::JobOptionsContract
assert_equal VALUE1, DataCollector.data[0][0]
assert_equal VALUE2, DataCollector.data[0][1]
assert_equal 1, DataCollector.data.size