require 'digest'
require 'aws-sdk'
require 'sinatra'

get '/' do
  haml :index
end

get '/:hash' do
  haml :audio, :locals => {:url => params[:hash]}
end

post '/' do
  code = params['code']
  hash = Digest::MD5.hexdigest(code)
  file_name = "#{hash}.wav"
  path_to_file = "/tmp/#{file_name}"

  `sonic_pi "recording_start; sleep 1; #{code}; sleep 2; recording_stop; sleep 1; recording_save('#{path_to_file}'); sleep 2"`

  sleep 15

	Aws.config[:credentials] = Aws::Credentials.new(
		ENV['BUCKETEER_AWS_ACCESS_KEY_ID'],
		ENV['BUCKETEER_AWS_SECRET_ACCESS_KEY']
	)
	Aws.config[:region]      = ENV['BUCKETEER_AWS_REGION']

  s3 = Aws::S3::Resource.new
  obj = s3.bucket(ENV['BUCKETEER_BUCKET_NAME']).object(file_name)
  obj.upload_file(path_to_file, { acl: 'public-read' })  # http://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html

  # Returns Public URL to the file
  haml :audio, :locals => {:url => obj.public_url}
end

__END__

@@ layout
%html
  = yield

@@ index
%div.title Hello world.
%form{ :action => "/", :method => "post"}
  %fieldset
    %textarea{ :name => "code", :class => "text"}
    %input{:type => "submit", :value => "Send", :class => "button"}

@@ audio
%audio{ :src=> locals[:url], :autoplay => false, :controls=>"controls" }
%p
  Link:
  %a{ :href=>locals[:url] }= locals[:url]
