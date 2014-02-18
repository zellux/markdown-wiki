require 'sinatra'
require "sinatra/reloader" if development?
require 'slim'
require 'redcarpet'
require 'pathname'

set :bind, 'localhost'
set :logging, :true

WIKI_ROOT = ENV['WIKI_ROOT'] || "#{settings.root}/sample"

helpers do
  def get_path(filename)
    segments = filename.split('::')[-2..-1] || [filename]
    ['', '.md', '.txt', '.markdown'].each do |suffix|
      filename = segments[-1]
      segments[-1] = filename + suffix
      path = File.join(WIKI_ROOT, segments)
      segments[-1] = filename
      puts path
      return path if File.file?(path)
    end
    nil
  end

  def ls_dir(dir)
    paths = Dir.glob(File.join(dir, '**', '*')).select { |e| File.file?(e) }
    basepath = Pathname.new(dir)
    files = paths.map { |e| Pathname.new(e).relative_path_from(basepath).to_s }
    lvl0 = []
    lvl1 = {}
    files.each do |e|
      segments = e.split(File::SEPARATOR)
      case segments.count
      when 1
        lvl0 << e
      when 2
        lvl1[segments[0]] ||= []
        lvl1[segments[0]] << segments[1]
      else
        puts 'At most 1 level dir supported'
      end
    end
    puts lvl1.inspect
    [lvl0, lvl1]
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
