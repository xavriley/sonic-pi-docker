require 'aws-sdk-s3'
require 'json'
require 'sidekiq'
require 'sidekiq/api'

Aws.config[:credentials] = Aws::Credentials.new(
  ENV['BUCKETEER_AWS_ACCESS_KEY_ID'],
  ENV['BUCKETEER_AWS_SECRET_ACCESS_KEY']
)
Aws.config[:region]      = ENV['BUCKETEER_AWS_REGION']

class RenderWorker
  include Sidekiq::Worker

  def perform(code, hash)
    file_name = "#{hash}.wav"
    metadata_name = "#{hash}.json"
    path_to_file = "/tmp/#{file_name}"

    s3 = Aws::S3::Resource.new
    obj = s3.bucket(ENV['BUCKETEER_BUCKET_NAME']).object(file_name)
    metadata_json = s3.bucket(ENV['BUCKETEER_BUCKET_NAME']).object(metadata_name)

    # our work here is done if the file with the same
    # hash already exists
    return true if obj.exists?

    # otherwise, let's begin
    `sonic_pi "recording_start; sleep 1;"`
    sleep 1
    `sonic_pi "#{code};"`
    sleep 30
    `sonic_pi stop`
    sleep 1
    `sonic_pi "recording_stop; sleep 1;"`
    sleep 1
    `sonic_pi "recording_save('#{path_to_file}'); sleep 2"`
    sleep 2

    # upload the recording to S3
    # http://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    obj.upload_file(path_to_file, {
      acl: 'public-read'
    })

    obj.wait_until_exists

    metadata_json.put({
      :acl => "public-read",
      :body => {"code": code}.to_json,
      :content_type => "text/json"
    })

    sleep 1

    puts "\r\n"
    puts obj.public_url
    puts metadata_json.public_url
  ensure
    # if the job fails for any reason stop the recording and kill any playing sounds
    `sonic_pi stop`
    sleep 1
    `sonic_pi "recording_stop; sleep 1;"`
    sleep 1
  end
end

