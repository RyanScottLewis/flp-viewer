require "../version"
require "../project"
require "./base"

require "html_builder"

class FLP::Formatter::HTML < FLP::Formatter::Base

    BOOTSTRAP_VERSION  = "4.3.1"
    JQUERY_VERSION     = "3.3.1"
    DATATABLES_VERSION = "1.10.19"

    @projects       : Array(Project)
    @build_duration : Time::Span

    def initialize(@projects, @build_duration)
    end

    # TODO: Holy fuck lol just use ECR
    def to_s(io)
      io << ::HTML.build do |builder|

        doctype

        html do

          head do

            title { text "FL Studio Projects" }
            link(rel: "stylesheet", href: "https://stackpath.bootstrapcdn.com/bootstrap/#{BOOTSTRAP_VERSION}/css/bootstrap.min.css", integrity: "sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T", crossorigin: "anonymous")
            link(rel: "stylesheet", href: "https://cdn.datatables.net/#{DATATABLES_VERSION}/css/dataTables.bootstrap4.min.css", crossorigin: "anonymous")

            script(src: "https://code.jquery.com/jquery-#{JQUERY_VERSION}.slim.min.js", integrity: "sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo", crossorigin: "anonymous") {}
            script(src: "https://cdn.datatables.net/#{DATATABLES_VERSION}/js/jquery.dataTables.min.js", crossorigin: "anonymous") {}
            script(src: "https://cdn.datatables.net/#{DATATABLES_VERSION}/js/dataTables.bootstrap4.min.js", crossorigin: "anonymous") {}

            script do
              # This should be named `raw` or something, because it just appends the string to the output.
              html "$(document).ready( function () { $('main table').DataTable(); } );"
            end

          end

          body(class: "container-fluid py-3") do

            header(class: "d-flex justify-content-between") do
              h1 { text "FL Studio Projects" }
            end

            hr

            main do

              table(class: "table table-sm table-bordered table-hover table-responsive") do
                thead(class: "thead-dark") do
                  tr do
                    th(scope: "col") { text "Path" }
                    th(scope: "col") { text "Channels" }
                    th(scope: "col") { text "Started At" }
                    th(scope: "col") { text "Work Time" }
                  end
                end

                tbody do
                  @projects.each do |project|

                    tr do
                      td { text project.path }
                      td { text project.channels.inspect }
                      td(class: "text-nowrap") { text project.started_at.inspect }
                      td(class: "text-nowrap") { text project.work_time.inspect }
                    end

                  end
                end
              end # table

            end # main

            hr

            footer do
              div(class: "text-muted d-flex justify-content-between") do

                div do
                  text "Generated in #{@build_duration.total_seconds}s"
                end

                div do
                  div { text "Powered by:" }

                  div(class: "ml-3") do

                    powered_by = [ # TODO: Move to CONST
                      { url: "https://github.com/RyanScottLewis/flp-viewer", name: "FLP Viewer", version: VERSION },
                      { url: "https://crystal-lang.org",                     name: "Crystal",    version: Crystal::VERSION },
                      { url: "https://getbootstrap.com",                     name: "Bootstrap",  version: BOOTSTRAP_VERSION },
                      { url: "https://jquery.com",                           name: "jQuery",     version: JQUERY_VERSION },
                      { url: "https://datatables.net",                       name: "DataTables", version: DATATABLES_VERSION },
                    ]

                    powered_by.each do |item|

                      div(class: "row") do
                        div(class: "col-6 text-nowrap") do
                          a(href: item[:url], target: "_blank") { text item[:name] }
                        end

                        div(class: "col-6 text-nowrap text-right") do
                          span { text item[:version] }
                        end
                      end

                    end

                  end

                end

              end
            end # footer

          end

        end

      end
    end

end
