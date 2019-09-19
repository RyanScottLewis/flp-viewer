require "./parser"
require "./errors"
require "./formatter/html"

module FLP
  class Application

    def self.call(arguments)
      new(arguments).call
    end

    @arguments : Array(String)

    def initialize(@arguments)
    end

    def call
      started_at = Time.now

      validate_arguments_length

      projects = @arguments.map do |path|
        validate_path_exists(path)
        parse_project(path)
      end

      build_duration = Time.now - started_at

      html = generate_html(projects, build_duration)

      puts html
    end

    protected def print_usage
      puts "Usage: flp PATHS..."
    end

    protected def validate_arguments_length
      return unless @arguments.empty?

      print_usage
      exit 1
    end

    protected def validate_path_exists(path)
      return if File.exists?(path)

      puts "Error: Path '#{path}' does not exist"
      exit 1
    end

    protected def parse_project(path)
      project = Parser.parse(path)

      project.path = path

      project
    rescue error : Error
      puts "Error: #{error}"
      exit 1
    end

    protected def generate_html(projects, build_duration)
      Formatter::HTML.new(projects, build_duration).to_s
    end

  end
end
