require 'digest'
require 'json'
require 'aws-sdk'
require 'sinatra'

require_relative './lib/workers/render_worker'

Aws.config[:credentials] = Aws::Credentials.new(
  ENV['BUCKETEER_AWS_ACCESS_KEY_ID'],
  ENV['BUCKETEER_AWS_SECRET_ACCESS_KEY']
)
Aws.config[:region]      = ENV['BUCKETEER_AWS_REGION']

get '/' do
  bucket = Aws::S3::Resource.new.bucket(ENV['BUCKETEER_BUCKET_NAME'])

  json_files = bucket.objects.select {|o| o.key =~ /\.json$/}

  sketches = json_files.map {|f|
    hash = f.key.gsub(".json", "")
    url = bucket.object("#{hash}.wav").public_url
    JSON.parse(f.get.body.read).merge({
      "hash" => hash,
      "url" => url
    })
  }

  haml :index, :locals => { :sketches => sketches }
end

get '/sketches/new' do
  haml :new
end

get '/sketches/:hash' do
  s3 = Aws::S3::Resource.new
  obj = s3.bucket(ENV['BUCKETEER_BUCKET_NAME']).object("#{params[:hash]}.wav")
  meta = s3.bucket(ENV['BUCKETEER_BUCKET_NAME']).object("#{params[:hash]}.json")

  if meta.exists?
    code = JSON.parse(meta.get.body.read).fetch("code", "")
  else
    code = ""
  end

  haml :audio, :locals => {:url => obj.public_url, :code => code}
end

post '/' do
  code = params['code']
  hash = Digest::MD5.hexdigest(code)

  RenderWorker.perform_async(code, hash)

  redirect to("/sketches/#{hash}")
end

__END__

@@ layout
%html
  %head
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <title>Sonic Pi Gallery</title>
    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>

    <!-- Latest compiled and minified JavaScript -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>

    <!-- Slate theme from Bootswatch -->
    <link href="https://maxcdn.bootstrapcdn.com/bootswatch/3.3.7/slate/bootstrap.min.css" rel="stylesheet" integrity="sha384-RpX8okQqCyUNG7PlOYNybyJXYTtGQH+7rIKiVvg1DLg6jahLEk47VvpUyS+E2/uJ" crossorigin="anonymous">

    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.32.0/codemirror.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.32.0/codemirror.min.css" />

  %body
    %nav.navbar.navbar-default
      .container-fluid
        .navbar-header
          %a.navbar-brand{:href => "/"} Sonic Pi Gallery
        #bs-example-navbar-collapse-1.collapse.navbar-collapse
          %ul.nav.navbar-nav.navbar-right
            %li
              %a.btn.btn-danger{:href => "/sketches/new"} Upload your own
    %div.container
      %div.row
        = yield

@@ index
- locals[:sketches].each do |sketch|
  %div.jumbotron
    %pre.pre-scrollable{ :style => "max-height: 150px" }
      %code= sketch["code"]
    %audio{ :src=> sketch["url"], :autoplay => false, :controls=>"controls" }
    %p
      %a{ :href => "/sketches/#{sketch["hash"]}" }= "permalink"

@@ new
:javascript
  $(document).ready( function() {
    var editor = CodeMirror.fromTextArea(document.getElementById("code"), {
      mode: "text/x-ruby",
      matchBrackets: true,
      lineNumbers: true,
      indentUnit: 4
    });
  });
%div.col-lg-6
  %form{ :action => "/", :method => "post", :class => "form-horizontal" }
    %fieldset
      %div.form-group
        %div.col-lg-10
          %textarea{ :name => "code", :id => "code", :class => "form-control", :rows => 10}
      %div.form-group
        %div.col-lg-10.col-lg-offset-2
          %input{:type => "submit", :value => "Submit", :class => "btn btn-primary"}

@@ audio
%pre
  %code= locals[:code]
%audio{ :src=> locals[:url], :autoplay => false, :controls=>"controls" }
%p
  Link:
  %a{ :href=>locals[:url] }= locals[:url]
