require 'sinatra'
require 'slim'
require 'redcarpet'

set :bind, 'localhost'

WIKI_ROOT = "#{settings.root}/sample"

helpers do
  def get_path(filename)
    filename.gsub!(/^.*(\\|\/)/, '')
    ['', '.md', '.txt', '.markdown'].each do |suffix|
      path = File.join(WIKI_ROOT, filename + suffix)
      return path if File.file?(path)
    end
    nil
  end

  def ls_dir(dir)
    Dir.glob("#{WIKI_ROOT}/*").map { |e| File.basename(e, File.extname(e)) }
  end

  def editor_link(path)
    %(wikieditor://iawriter#path=#{CGI::escape(path)})
  end

  def customed_markdown(raw)
    processed = raw.gsub(/\[\[(.*?)\]\]/, '<a href="/wiki/\1">\1</a>')
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML,
      :autolink => true,
      :fenced_code_blocks => true,
      :disable_indented_code_blocks=>true,
      :strikethrough => true,
      :superscript => true,
      :underline => true,
      :highlight => true,
      :quote => true,
      :footnotes => true,
    )
    markdown.render(processed)
  end
end

get '/' do
  files = ls_dir(WIKI_ROOT)
  slim :index, :locals => { :files => files }
end

get '/style.css' do
  scss :stylesheet
end

get '/wiki/:page' do
  path = get_path(params[:page])
  if path
    content = File.open(path).read
    slim :page, :locals => { :raw => content, :path => path }
  else
    halt 404
  end
end

not_found do
  '404'
end
