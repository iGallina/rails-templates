# -*- coding: utf-8 -*-

require 'open-uri'

def download file_name, output_path
  assets_path = 'https://github.com/61bits/rails-templates/raw/master/assets'
  puts " \033[1;32mdownloading\033[0m    #{output_path}/#{file_name}"
  File.open("#{output_path}/#{file_name}", 'wb') { |f| f.write open("#{assets_path}/#{file_name}").read }
end

def command?(name)
  `which #{name}`
  $?.success?
end

def ask_question question
  ask "    \033[1;32masking\033[0m    #{question}?"
end

def ask_yes_or_no_question question
  yes? "    \033[1;32masking\033[0m    #{question}?"
end

# ============================================================================
# Unicorn + Foreman
# ============================================================================

gem 'unicorn'
gem 'foreman', group: :development

file 'Procfile', <<FILE
web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
FILE

file '.env', <<FILE
WEB_CONCURRENCY=1
RACK_ENV=none
RAILS_ENV=development
APP_HOSTNAME=localhost
FILE

file 'config/unicorn.rb', <<RUBY
worker_processes Integer(ENV["WEB_CONCURRENCY"] || 5)
ENV['RAILS_ENV'] == 'development' ? timeout(90) : timeout(15)
preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)

  if defined?(Resque) and Rails.env.production?
    Resque.redis.quit
    Rails.logger.info('Disconnected from Redis')
  end
end 

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)

  if defined?(Resque) and Rails.env.production?
    Resque.redis = ENV['REDIS_URI']
    Rails.logger.info('Connected to Redis')
  end
end
RUBY

application(nil, env: :development) do <<RUBY

  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger.const_get(ENV['LOG_LEVEL'] ? ENV['LOG_LEVEL'].upcase : 'DEBUG')
RUBY
end

# ============================================================================
# Application config
# ============================================================================

application do <<RUBY

    config.filter_parameters += [:password, :password_confirmation]    
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**/*.{rb,yml}').to_s]
RUBY
end

if ask_yes_or_no_question "Change locale to pt-BR and time zone to Brazil's official time"
application do <<RUBY

    config.i18n.default_locale = 'pt-BR'
    config.time_zone = 'Brasilia'
RUBY
end
end

# ============================================================================
# Pry
# ============================================================================

gem 'pry'
gem 'pry-doc'

application do <<RUBY

    console do
      require 'pry'
      config.console = Pry
    end
RUBY
end

# ============================================================================
# Heroku
# ============================================================================

gem 'rails_12factor', group: :production

# ============================================================================
# Compass
# ============================================================================

gem 'compass-rails', '~> 2.0.alpha.0'
gem 'compass-normalize'
gem 'singularitygs'
gem 'singularity-extras'
gem 'breakpoint'
gem 'color-schemer'
gem 'toolkit'
gem 'oily_png'

# ============================================================================
# SMACSS
# ============================================================================

Dir.mkdir 'app/assets/stylesheets/base'
file 'app/assets/stylesheets/base/_all.sass', <<SASS
// ---------------------------------------------------------------------------
//  BASE IMPORTS
// ---------------------------------------------------------------------------
// Styles relevant to the hole application, always.

// COMPASS
// tollkit includes: compass, color-schemer and breakpoint
@import "toolkit" 
@import "singularitygs"
@import "singularity-extras"
@import "normalize"

// BASE PARTIALS
@import "variables"
@import "mixins"
@import "fonts"
@import "lt_ie9"

// BASE STYLES

+establish-baseline

html
  overflow-y: scroll

body
  color: $text-color
  font-family: $sans-family
  font-size: $base-font-size
  line-height: $base-line-height

*::selection
  background: $text-selection-background
  color: $text-selection-color

SASS

file 'app/assets/stylesheets/base/_variables.sass', <<SASS
// SINGULARITYGS & BREAKPOINT
$bp-320: 320px
$bp-768: 768px
$bp-1024: 1024px
$bp-1280: 1280px
$bp-1440: 1440px
$bp-1920: 1920px
//$grids: add-grid(4 at $bp-320)
//$grids: add-grid(6 at $bp-768)
//$grids: add-grid(9 at $bp-1024)
//$grids: add-grid(12 at $bp-1280)
//$grids: 12
//$gutters: .2
$breakpoint-no-queries: false
$breakpoint-no-query-fallbacks: true

// VERTICAL RHYTHM
$base-font-size: 14px
$base-line-height: 20px
$round-to-nearest-half-line: false
$font-unit: 14px

// COMPASS CROSS-BROWSER SUPPORT
$legacy-support-for-ie6: false
$legacy-support-for-ie7: false
$legacy-support-for-ie8: false

// COMPASS DEFAULTS
$default-text-shadow-blur: 0

// COLORS
$gray-dark: #333333
$yellow: #ffc40d

// TYPOGRAPHY
$text-selection-color: $gray-dark
$text-selection-background: lighten($yellow, 40)
$sans-family: "Helvetica Neue", Helvetica, Arial, sans-serif
$serif-family: "Georgia", "Times New Roman", Times, Cambria, Georgia, serif
$monospace-family: "Monaco", "Courier New", monospace, sans-serif
$text-color: $gray-dark !default

SASS

file 'app/assets/stylesheets/base/_fonts.sass', <<SASS
@charset "UTF-8"
// @import url(http://fonts.googleapis.com/css?family=PT+Sans+Caption:400,700)
// +font-face("Font", font-files("font.woff", woff, "font.otf", opentype, "font.ttf", truetype, "font.svg", svg), "font.eot", bold, normal)
SASS

Dir.mkdir 'vendor/assets/fonts'
file 'vendor/assets/fonts/.gitkeep', ''

file 'app/assets/stylesheets/base/_mixins.sass', <<'SASS'
=background-2x($background, $file: 'png')
  $image: #{$background+"."+$file}
  $image2x: #{$background+"@2x."+$file}
  
  background: image-url($image) no-repeat
  @media (min--moz-device-pixel-ratio: 1.3),(-o-min-device-pixel-ratio: 2.6/2),(-webkit-min-device-pixel-ratio: 1.3),(min-device-pixel-ratio: 1.3),(min-resolution: 1.3dppx)
    background-image: image-url($image2x)
    background-size: image-width($image) image-height($image)

=improve-text-rendering
  text-rendering: optimizeLegibility
  -webkit-font-smoothing: antialiased

=fade-on-hover
  +transition(0.25s)
  &:hover
    +opacity(0.8)

=debug
  background-color: rgba(red,0.6)

SASS

file 'app/assets/stylesheets/base/_lt_ie9.sass', <<SASS
html.lt-ie9
  body
    header
      display: none
    section.page
      display: none
    footer
      display: none
SASS

Dir.mkdir 'app/assets/stylesheets/layouts'
file 'app/assets/stylesheets/layouts/_all.sass', <<SASS
// ---------------------------------------------------------------------------
//  LAYOUT IMPORTS
// ---------------------------------------------------------------------------
// Styles relevant only to the page layouts.
SASS

Dir.mkdir 'app/assets/stylesheets/modules'
file 'app/assets/stylesheets/modules/_all.sass', <<SASS
// ---------------------------------------------------------------------------
//  MODULE IMPORTS
// ---------------------------------------------------------------------------
// Styles relevant only to visual module components.
SASS

Dir.mkdir 'app/assets/stylesheets/states'
file 'app/assets/stylesheets/states/_all.sass', <<SASS
// ---------------------------------------------------------------------------
//  STATE IMPORTS
// ---------------------------------------------------------------------------
// Styles relevant to state specializations.
SASS

Dir.mkdir 'app/assets/stylesheets/themes'
file 'app/assets/stylesheets/themes/_all.sass', <<SASS
// ---------------------------------------------------------------------------
//  THEME IMPORTS
// ---------------------------------------------------------------------------
// Styles relevant to layout themes.
SASS

File.delete 'app/assets/stylesheets/application.css'
file 'app/assets/stylesheets/application.sass', <<SASS
@import "base/all"
@import "layouts/all"
@import "modules/all"
@import "states/all"
@import "themes/all"
SASS

# ============================================================================
# Slim
# ============================================================================

gem 'slim'

application(nil, env: :development) do <<RUBY
Slim::Engine.set_default_options pretty: true, sort_attrs: false, format: :html5
RUBY
end

application(nil, env: :production) do <<RUBY
Slim::Engine.set_default_options format: :html5
RUBY
end

# ============================================================================
# crossdomain.xml, robots.txt and humans.txt
# ============================================================================

file 'public/crossdomain.xml', <<XML
<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "http://www.adobe.com/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
<!-- Read this: www.adobe.com/devnet/articles/crossdomain_policy_file_spec.html -->
<!-- Most restrictive policy: -->
	<site-control permitted-cross-domain-policies="none"/>
<!-- Least restrictive policy: -->
<!--
	<site-control permitted-cross-domain-policies="all"/>
	<allow-access-from domain="*" to-ports="*" secure="false"/>
	<allow-http-request-headers-from domain="*" headers="*" secure="false"/>
-->
<!--
  If you host a crossdomain.xml file with allow-access-from domain="*"
  and don’t understand all of the points described here, you probably
  have a nasty security vulnerability. ~ simon willison
-->
</cross-domain-policy>
XML

file 'public/robots.txt', <<TXT
# http://www.robotstxt.org/
User-agent: *
Disallow:
TXT

team_name = ask_question 'Team name'
team_url = ask_question 'Team full url'
styled_team_name = command?('figlet') ? `figlet -f larry3d #{team_name}` : team_name
file 'public/humans.txt', <<TXT
#{styled_team_name}

The humans.txt file explains the team, technology, 
and creative assets behind this site.
http://humanstxt.org

_______________________________________________________________________________
TEAM

This site was hand-crafted by #{team_name}
#{team_url}

_______________________________________________________________________________
TECHNOLOGY

Ruby on Rails
http://rubyonrails.org

HTML5 Boilerplate
http://html5boilerplate.com

Slim
http://slim-lang.com

Sass
http://sass-lang.com

Compass
http://compass-style.org

SingularityGS
http://singularity.gs/

jQuery
http://jquery.com

Modernizr
http://modernizr.com

CoffeeScript
http://coffeescript.org
TXT

# ============================================================================
# Pages Controller, Frontend Controller, HTML5Boilerplate Layout
# ============================================================================

File.delete 'app/views/layouts/application.html.erb'

file 'app/views/layouts/application.slim', <<'SLIM'
doctype html

/[if lt IE 7]
  <html class="no-js lt-ie9 lt-ie8 lt-ie7" lang="#{I18n.locale}">
/[if IE 7]
  <html class="no-js lt-ie9 lt-ie8" lang="#{I18n.locale}">
/[if IE 8]
  <html class="no-js lt-ie9" lang="#{I18n.locale}">

/![if gt IE 8]><!
html.no-js lang="#{I18n.locale}"
  /! <![endif]

  head
    title #{(content_for?(:title) ? "#{yield :title} — " : "") + Rails.application.class.parent_name }
    == render 'layouts/metatags'
    == render 'layouts/favicons'

    == csrf_meta_tags
    == stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track' => true
    == javascript_include_tag 'application', 'data-turbolinks-track' => true
    /[if lt IE 9]
      == javascript_include_tag 'nwmatcher-1.2.5', 'data-turbolinks-track' => true
      == javascript_include_tag 'selectivizr', 'data-turbolinks-track' => true
      == javascript_include_tag 'html5shiv-printshiv', 'data-turbolinks-track' => true

  body class="#{yield :body_class}"
    == render 'layouts/browser_warning'

    section.page
      == yield
SLIM

file 'app/views/layouts/_metatags.slim', <<'SLIM'
// html metatags
meta charset="utf-8"
meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"
meta name="author" content="TEAM_NAME — TEAM_URL"
meta name="description" content="#{content_for?(:description) ? yield(:description) : Rails.application.class.parent_name}"
meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1.0, maximum-scale=1.0"

// opengraph metatags
meta property="og:image" content="http://#{ENV['APP_HOSTNAME']}/og-image.png"
meta property="og:type" content="website"
meta property="og:url" content="http://#{ENV['APP_HOSTNAME']}"
meta property="og:title" content="#{content_for?(:title) ? yield(:title).to_s + '— ' : ''}#{Rails.application.class.parent_name}"
meta property="og:description" content="#{content_for?(:description) ? yield(:description) : Rails.application.class.parent_name}"
meta property="og:locale" content="pt_BR"
// meta property="fb:admins" content="#admin-id" 

// humans.txt
link rel="author" href="/humans.txt"
SLIM

gsub_file 'app/views/layouts/_metatags.slim', 'TEAM_NAME', team_name
gsub_file 'app/views/layouts/_metatags.slim', 'TEAM_URL', team_url

file 'app/views/layouts/_favicons.slim', <<'SLIM'
== favicon_link_tag '/apple-touch-icon-144x144-precomposed.png', rel: 'apple-touch-icon', \
                                                                 type: 'image/png', \
                                                                 sizes: '144x144'
== favicon_link_tag '/apple-touch-icon-114x114-precomposed.png', rel: 'apple-touch-icon', \
                                                                 type: 'image/png', \
                                                                 sizes: '114x114'
== favicon_link_tag '/apple-touch-icon-72x72-precomposed.png', rel: 'apple-touch-icon', \
                                                               type: 'image/png', \
                                                               sizes: '72x72'
== favicon_link_tag '/apple-touch-icon-57x57-precomposed.png', rel: 'apple-touch-icon', \
                                                               type: 'image/png', \
                                                               sizes: '57x57'
== favicon_link_tag '/favicon.png', type: 'image/png'
== favicon_link_tag '/favicon.ico'
SLIM

[ 'favicon.png', 
  'favicon.ico', 
  'apple-touch-icon-144x144-precomposed.png',
  'apple-touch-icon-114x114-precomposed.png',
  'apple-touch-icon-72x72-precomposed.png',
  'apple-touch-icon-57x57-precomposed.png',
  'apple-touch-icon-precomposed.png',
  'apple-touch-icon.png',
  'og-image.png' ].each { |f| download f, 'public' }

file 'app/views/layouts/_browser_warning.slim', <<'SLIM'
/[if lt IE 9]
  p.chromeframe
    == t 'app.lt_ie_9_warning'
SLIM

Dir.mkdir 'app/views/pages'

file 'app/views/pages/index.slim', <<SLIM
h1 pages#index
SLIM

file 'app/controllers/pages_controller.rb', <<RUBY
class PagesController < ApplicationController
  def index; end

  def show
    render params[:template]
  end
end
RUBY

route "root to: 'pages#index'"
route "get ':slug' => 'pages#show', as: :page"

Dir.mkdir 'app/views/frontend'

file 'app/controllers/frontend_controller.rb', <<RUBY
class FrontendController < ApplicationController
  def index
    @entries = Dir.entries(Rails.root.join('app', 'views', 'frontend')) - [".", "..", "index.slim"]
  end

  def show
    render params[:template]
  end
end
RUBY

file 'app/views/frontend/index.slim', <<SLIM
- if @entries.present?
  h1 Frontend Files:
  ul
    - @entries.each do |entry|
      li = link_to entry, frontend_path(entry.gsub(/(.html)?\.\w+$/, ''))
    
h1 Comparison Sheet:

section.page
  #content
    h1 Heading 1
    h2 Heading 2
    h3 Heading 3
    h4 Heading 4
    h5 Heading 5
    h6 Heading 6
    section
      h1 Heading 1 (in section)
      h2 Heading 2 (in section)
      h3 Heading 3 (in section)
      h4 Heading 4 (in section)
      h5 Heading 5 (in section)
      h6 Heading 6 (in section)
    article
      h1 Heading 1 (in article)
      h2 Heading 2 (in article)
      h3 Heading 3 (in article)
      h4 Heading 4 (in article)
      h5 Heading 5 (in article)
      h6 Heading 6 (in article)
    header
      hgroup
        h1 Heading 1 (in hgroup)
        h2 Heading 2 (in hgroup)
      nav
        ul
          li
            a href="#" navigation item #1
          li
            a href="#" navigation item #2
          li
            a href="#" navigation item #3
    h1 Text-level semantics
    p hidden=true This should be hidden in all browsers, apart from IE6
    p
      ' Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. 
        Aenean massa. Cum sociis natoque penatibus et m. 
        Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. 
        Aenean massa. Cum sociis natoque penatibus et m. 
        Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. 
        Aenean massa. Cum sociis natoque penatibus et m.
    p
      ' Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. 
        Aenean massa. Cum sociis natoque penatibus et m. 
        Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. 
        Aenean massa. Cum sociis natoque penatibus et m. 
        Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. 
        Aenean massa. Cum sociis natoque penatibus et m.
    address Address somewhere, world
    hr
    hr style="height:4px; border:solid #000; border-width:1px 0;"
    p
      |  The 
      a href="#"
        | a element
      |  example
      br
      |  The 
      abbr
        | abbr element
      |  and 
      abbr title="Title text"
        | abbr element with title
      |  examples
      br
      |  The 
      b
        | b element
      |  example
      br
      |  The 
      cite
        | cite element
      |  example
      br
      |  The 
      code
        | code element
      |  example
      br
      |  The 
      del
        | del element
      |  example
      br
      |  The 
      dfn
        | dfn element
      |  and 
      dfn title="Title text"
        | dfn element with title
      |  examples
      br
      |  The 
      em
        | em element
      |  example
      br
      |  The 
      i
        | i element
      |  example
      br
      |  The img element 
      img src="http://lorempixel.com/16/16" alt=""
      |  example
      br
      |  The 
      ins
        | ins element
      |  example
      br
      |  The 
      kbd
        | kbd element
      |  example
      br
      |  The 
      mark
        | mark element
      |  example
      br
      |  The 
      q
        | q element 
        q
          | inside
        |  a q element
      |  example
      br
      |  The 
      s
        | s element
      |  example
      br
      |  The 
      samp
        | samp element
      |  example
      br
      |  The 
      small
        | small element
      |  example
      br
      |  The 
      span
        | span element
      |  example
      br
      |  The 
      strong
        | strong element
      |  example
      br
      |  The 
      sub
        | sub element
      |  example
      br
      |  The 
      sup
        | sup element
      |  example
      br
      |  The 
      u
        | u element
      |  example
      br
      |  The 
      var
        | var element
      |  example 
    h1 Embedded content
    h3 audio
    audio controls=true
    audio
    h3 img
    img src="http://lorempixel.com/100/100" alt=""
    a href="#"
      img src="http://lorempixel.com/100/100" alt=""
    h3 svg
    svg width="100px" height="100px"
      circle cx="100" cy="100" r="100" fill="#ff0000"
    h3 video
    video controls=true
    video
    h1 Interactive content
    h3 details / summary
    details
      summary More info
      p Additional information
      ul
        li Point 1
        li Point 2
    h1 Grouping content
    p 
      ' Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. 
        Aenean massa. Cum sociis natoque penatibus et m. 
    h3 pre
    pre
      ' Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. 
        Aenean massa. Cum sociis natoque penatibus et m. 
    pre
      code = '<html> <head> </head> <body> <div class="main"> <div> </body> </html>'
    h3 blockquote
    blockquote
      p = 'Some sort of famous witty quote marked up with a <blockquote> and a child <p> element.'
    blockquote =  'Even better philosophical quote marked up with just a <blockquote> element.'
    h3 ordered list
    ol
      li list item 1
      li
        | list item 1 
        ol
          li list item 2
          li
            | list item 2 
            ol
              li list item 3
              li list item 3
          li list item 2
          li list item 2
      li list item 1
      li list item 1
    h3 unordered list
    ul
      li list item 1
      li 
        | list item 1 
        ul
          li list item 2
          li 
            | list item 2 
            ul
              li list item 3
              li list item 3
          li list item 2
          li list item 2
      li list item 1
      li list item 1
    h3 description list
    dl
      dt Description name
      dd Description value
      dt Description name
      dd Description value
      dd Description value
      dt Description name
      dt Description name
      dd Description value
    h3 figure
    figure
      img src="http://lorempixel.com/400/200" alt=""
      figcaption Figcaption content
    h1 Tabular data
    table
      caption Jimi Hendrix - albums
      thead
        tr
          th Album
          th Year
          th Price
      tfoot
        tr
          th Album
          th Year
          th Price
      tbody
        tr
          td Are You Experienced
          td 1967
          td $10.00
        tr
          td Axis Bold as Love
          td 1967
          td $12.00
        tr
          td Electric Ladyland
          td 1968
          td $10.00
        tr
          td Band of Gypsys
          td 1970
          td $12.00
    h1 Forms
    form
      fieldset
        legend Inputs as descendents of labels (form legend). This doubles up as a long legend that can test word wrapping.
        p
          label
            | Text input 
            input type="text" value="default value that goes on and on without stopping or punctuation"
        p
          label
            | Email input 
            input type="email"
        p
          label
            | Search input 
            input type="search"
        p
          label
            | Tel input 
            input type="tel"
        p
          label
            | URL input 
            input type="url" placeholder="http://"
        p
          label
            | Password input 
            input type="password" value="password"
        p
          label
            | File input 
            input type="file"
        p
          label
            | Radio input 
            input type="radio" name="rad"
        p
          label
            | Checkbox input 
            input type="checkbox"
        p
          label
            input type="radio" name="rad"
            |  Radio input
        p
          label
            input type="checkbox"
            |  Checkbox input
        p
          label
            | Select field 
            select
              option Option 01
              option Option 02
        p
          label
            | Textarea 
            textarea cols="30" rows="5" Textarea text
      fieldset
        legend Inputs as siblings of labels
        p
          label for="ic" Color input
          input#ic type="color" value="#000000"
        p
          label for="in" Number input
          input#in type="number" min="0" max="10" value="5"
        p
          label for="ir" Range input
          input#ir type="range" value="10"
        p
          label for="idd" Date input
          input#idd type="date" value="1970-01-01"
        p
          label for="idm" Month input
          input#idm type="month" value="1970-01"
        p
          label for="idw" Week input
          input#idw type="week" value="1970-W01"
        p
          label for="idt" Datetime input
          input#idt type="datetime" value="1970-01-01T00:00:00Z"
        p
          label for="idtl" Datetime-local input
          input#idtl type="datetime-local" value="1970-01-01T00:00"
        p
          label for="irb" Radio input
          input#irb type="radio" name="rad"
        p
          label for="icb" Checkbox input
          input#icb type="checkbox"
        p
          input#irb2 type="radio" name="rad"
          label for="irb2" Radio input
        p
          input#icb2 type="checkbox"
          label for="icb2" Checkbox input
        p
          label for="s" Select field
          select#s
            option Option 01
            option Option 02
        p
          label for="t" Textarea
          textarea#t cols="30" rows="5" Textarea text
      fieldset
        legend Clickable inputs and buttons
        p: input type="image" src="http://lorempixel.com/90/24" alt="Image (input)"
        p: input type="reset" value="Reset (input)"
        p: input type="button" value="Button (input)"
        p: input type="submit" value="Submit (input)"
        p: input type="submit" value="Disabled (input)" disabled=true
        p: button type="reset" Reset (button)
        p: button type="button" Button (button)
        p: button type="submit" Submit (button)
        p: button type="submit" disabled=true Disabled (button)
      fieldset#boxsize
        legend box-sizing tests
        div: input type="text" value="text"
        div: input type="email" value="email"
        div: input type="search" value="search"
        div: input type="url" value="http://example.com"
        div: input type="password" value="password"
        div: input type="color" value="#000000"
        div: input type="number" value="5"
        div: input type="range" value="10"
        div: input type="date" value="1970-01-01"
        div: input type="month" value="1970-01"
        div: input type="week" value="1970-W01"
        div: input type="datetime" value="1970-01-01T00:00:00Z"
        div: input type="datetime-local" value="1970-01-01T00:00"
        div: input type="radio"
        div: input type="checkbox"
        div
          select
            option Option 01
            option Option 02
        div: textarea cols="30" rows="5" Textarea text
        div: input type="image" src="http://lorempixel.com/90/24" alt="Image (input)"
        div: input type="reset" value="Reset (input)"
        div: input type="button" value="Button (input)"
        div: input type="submit" value="Submit (input)"
        div: button type="reset" Reset (button)
        div: button type="button" Button (button)
        div: button type="submit"
SLIM

route "get 'frontend/:template' => 'frontend#show'"
route "get 'frontend'           => 'frontend#index'"

# ============================================================================
# Formtastic
# ============================================================================

if ask_yes_or_no_question 'Install formtastic'
  gem 'formtastic'
  generate 'formtastic:install'
end

# ============================================================================
# rvm, ruby 2.0
# ============================================================================

inject_into_file 'Gemfile', after: "source 'https://rubygems.org'\n" do <<RUBY
ruby '2.0.0'
RUBY
end

file '.ruby-version', <<FIN
ruby-2.0.0-p247
FIN

# ============================================================================
# Licence
# ============================================================================

if ask_yes_or_no_question 'Is this free software'

file 'LICENSE', <<FILE
DUAL LICENSE: GPL3 and MIT


The GNU Public License, Version 3 (GPL3)

Copyright (c) TEAM_NAME

This program is free software: you can redistribute it and/or modify it under 
the terms of the GNU General Public License as published by the 
Free Software Foundation, either version 3 of the License, or (at your option) 
any later version.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with 
this program.  If not, see <http://www.gnu.org/licenses/>.


The MIT License (MIT)

Copyright (c) TEAM_NAME

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
FILE

gsub_file 'LICENSE', 'TEAM_NAME', team_name

else

license_date = ask_question 'Software license date'
license_licensee = ask_question 'Software licensee'
license_software_name = ask_question 'Software name'

file 'LICENSE', <<FILE
1. Preamble: This Agreement, signed on LICENSE_DATE [hereinafter: Effective Date]
   governs the relationship between LICENSE_LICENSEE, (hereinafter: Licensee) 
   and TEAM_NAME (Hereinafter: Licensor). 
   This Agreement sets the terms, rights, restrictions and obligations on using 
   SOFTWARE_NAME (hereinafter: The Software) created and owned by 
   Licensor, as detailed herein 
2. License Grant: Licensor hereby grants Licensee a Sublicensable, 
   Non-assignable & non-transferable, Commercial, Royalty free, Including 
   the rights to create but not distribute derivative works, Non-exclusive 
   license, all with accordance with the terms set forth and other legal 
   restrictions set forth in 3rd party software used while running Software.
   2.1. Limited: Licensee may use Software for the purpose of:
        2.1.1. Running Software on Licensee’s Website[s] and Server[s];
        2.1.2. Allowing 3rd Parties to run Software on Licensee’s Website[s] 
               and Server[s];
        2.1.3. Publishing Software’s output to Licensee and 3rd Parties;
        2.1.4. Distribute verbatim copies of Software’s output 
               (including compiled binaries);
        2.1.5. Modify Software to suit Licensee’s needs and specifications.
   2.2. Binary Restricted: Licensee may sublicense Software as a part of a 
        larger work containing more than Software, distributed solely in 
        Object or Binary form under a personal, non-sublicensable, 
        limited license.
        Such redistribution shall be limited to codebases.
   2.3. Non Assignable & Non-Transferable: Licensee may not assign or transfer 
        his rights and duties under this license.
   2.4. Commercial, Royalty Free: Licensee may use Software for any purpose, 
        including paid-services, without any royalties
   2.5. Including the Right to Create Derivative Works: Licensee may create 
        derivative works based on Software, including amending Software’s source
        code, modifying it, integrating it into a larger work or removing 
        portions of Software, as long as no distribution of the derivative 
        works is made
   2.6. With Attribution Requirements﻿: 
        Link back to you from a site running the software.
3. Term & Termination: The Term of this license shall be until terminated. 
   Licensor may terminate this Agreement, including Licensee’s license 
   in the case where Licensee:
   3.1. became insolvent or otherwise entered into any liquidation process; or
   3.2. exported The Software to any jurisdiction where licensor may not enforce
        his rights under this agreements in; or
   3.3. Licenee was in breach of any of this license's terms and conditions and 
        such breach was not cured, immediately upon notification; or
   3.4. Licensee in breach of any of the terms of clause 2 to this license; or
   3.5. Licensee otherwise entered into any arrangement which caused Licensor to 
        be unable to enforce his rights under this License.
4. Payment: In consideration of the License granted under clause 2, Licensee 
   shall pay Licensor a fee, via Credit-Card, PayPal or any other mean which 
   Licensor may deem adequate. 
   Failure to perform payment shall construe as material breach 
   of this Agreement.
5. Upgrades, Updates and Fixes: Licensor may provide Licensee, from time to time, 
   with Upgrades, Updates or Fixes, as detailed herein and according to his 
   sole discretion. Licensee hereby warrants to keep The Software up-to-date 
   and install all relevant updates and fixes, and may, at his sole discretion, 
   purchase upgrades, according to the rates set by Licensor. 
   Licensor shall provide any update or Fix free of charge; however, nothing in 
   this Agreement shall require Licensor to provide Updates or Fixes.
   5.1. Upgrades: for the purpose of this license, an Upgrade shall be a material
        amendment in The Software, which contains new features and or major 
        performance improvements and shall be marked as a new version number.
        For example, should Licensee purchase The Software under version 1.X.X, 
        an upgrade shall commence under number 2.0.0.
   5.2. Updates: for the purpose of this license, an update shall be a minor 
        amendment in The Software, which may contain new features or minor 
        improvements and shall be marked as a new sub-version number. 
        For example, should Licensee purchase The Software under version 1.1.X, 
        an upgrade shall commence under number 1.2.0.
   5.3. Fix: for the purpose of this license, a fix shall be a minor amendment in 
        The Software, intended to remove bugs or alter minor features which 
        impair the The Software's functionality. A fix shall be marked as a new 
        sub-sub-version number. For example, should Licensee purchase Software 
        under version 1.1.1, an upgrade shall commence under number 1.1.2.
6. Support: Software is provided under an AS-IS basis and without any support, 
   updates or maintenance. Nothing in this Agreement shall require Licensor to 
   provide Licensee with support or fixes to any bug, failure, mis-performance 
   or other defect in The Software.
   6.1. Bug Notification: Licensee may provide Licensor of details regarding any 
        bug, defect or failure in The Software promptly and with no delay from 
        such event; Licensee shall comply with Licensor's request for information
        regarding bugs, defects or failures and furnish him with information, 
        screenshots and try to reproduce such bugs, defects or failures.
   6.2. Feature Request: Licensee may request additional features in Software, 
        provided, however, that (i) Licesee shall waive any claim or right in 
        such feature should feature be developed by Licensor; (ii) Licensee shall
        be prohibited from developing the feature, or disclose such feature 
        request, or feature, to any 3rd party directly competing with Licensor or
        any 3rd party which may be, following the development of such feature, in
        direct competition with Licensor; (iii) Licensee warrants that feature 
        does not infringe any 3rd party patent, trademark, trade-secret or any 
        other intellectual property right; and (iv) Licensee developed, 
        envisioned or created the feature solely by himself.
7. Liability:  To the extent permitted under Law, The Software is provided under 
   an AS-IS basis. Licensor shall never, and without any limit, be liable for 
   any damage, cost, expense or any other payment incurred by Licesee as a result 
   of Software’s actions, failure, bugs and/or any other interaction between 
   The Software  and Licesee’s end-equipment, computers, other software or any 
   3rd party, end-equipment, computer or services.  Moreover, Licensor shall  
   never be liable for any defect in source code written by Licensee when relying 
   on The Software or using The Software’s source code.
8. Warranty:  
   8.1. Intellectual Property: Licensor hereby warrants that The Software does 
        not violate or infringe any 3rd party claims in regards to intellectual 
        property, patents and/or trademarks and that to the best of its knowledge
        no legal action has been taken against it for any infringement or 
        violation of any 3rd party intellectual property rights.
   8.2. No-Warranty: The Software is provided without any warranty; Licensor 
        hereby disclaims any warranty that The Software shall be error free, 
        without defects or code which may cause damage to Licensee’s computers or
        to Licensee, and that Software shall be functional. Licensee shall be 
        solely liable to any damage, defect or loss incurred as a result of 
        operating software and undertake the risks contained in running 
        The Software on License’s Server[s] and Website[s].
   8.3. Prior Inspection: Licensee hereby states that he inspected The Software 
        thoroughly and found it satisfactory and adequate to his needs, that it 
        does not interfere with his regular operation and that it does meet the 
        standards and scope of his computer systems and architecture. Licensee 
        found that The Software interacts with his development, website and 
        server environment and that it does not infringe any of End User License
        Agreement of any software Licensee may use in performing his services. 
        Licensee hereby waives any claims regarding The Software's 
        incompatibility, performance, results and features, and warrants that he 
        inspected the The Software.
9. No Refunds: Licensee warrants that he inspected The Software according to 
   clause 7(c) and that it is adequate to his needs. Accordingly, as The Software
   is intangible goods, Licensee shall not be, ever, entitled to any refund, 
   rebate, compensation or restitution for any reason whatsoever, even if 
   The Software contains material flaws.
10. Indemnification: Licensee hereby warrants to hold Licensor harmless and 
    indemnify Licensor for any lawsuit brought against it in regards to 
    Licensee’s use of The Software in means that violate, breach or otherwise 
    circumvent this license, Licensor's intellectual property rights or 
    Licensor's title in The Software. Licensor shall promptly notify Licensee
    in case of such legal action and request Licensee’s consent prior to any 
    settlement in relation to such lawsuit or claim.
11. Governing Law, Jurisdiction: Licensee hereby agrees not to initiate 
    class-action lawsuits against Licensor in relation to this license and 
    to compensate Licensor for any legal fees, cost or attorney fees should 
    any claim brought by Licensee against Licensor be denied, in part or in full.
FILE

gsub_file 'LICENSE', 'LICENSE_DATE', license_date
gsub_file 'LICENSE', 'LICENSE_LICENSEE', license_licensee
gsub_file 'LICENSE', 'TEAM_NAME', team_name
gsub_file 'LICENSE', 'SOFTWARE_NAME', license_software_name

end

# ============================================================================
# Postgres
# ============================================================================

gem 'pg'

gsub_file 'Gemfile', "gem 'sqlite3'", "# gem 'sqlite3'"
gsub_file 'config/database.yml', /^(?!#)/, '#'

database_prefix = ask_question 'What is your database prefix'
database_username = ask_question 'What is your database username'
database_password = ask_question 'What is your database password'

append_file 'config/database.yml', <<YML
development:
  adapter: postgresql
  encoding: unicode
  database: #{database_prefix}_development
  username: #{database_username}
  password: #{database_password}
  pool: 5
  timeout: 5000

production:
  adapter: postgresql
  encoding: unicode
  database: #{database_prefix}_production
  username: #{database_username}
  password: #{database_password}
  pool: 5
  timeout: 5000

test: &test
  adapter: postgresql
  encoding: unicode
  database: #{database_prefix}_test
  username: #{database_username}
  password: #{database_password}
  pool: 5
  timeout: 5000
YML

rake 'db:create:all'
rake 'db:migrate'

# ============================================================================
# Git
# ============================================================================

append_file '.gitignore', <<FILE
*.gem
*.rbc
.config
coverage
InstalledFiles
lib/bundler/man
pkg
rdoc
spec/reports
test/tmp
test/version_tmp

# YARD artifacts
.yardoc
_yardoc
doc/

# Sublime Text files
*.sublime-project
*.sublime-workspace

# Mac DS_Store
**/.DS_Store
.DS_Store
FILE

git :init
git add: "."
git commit: "-am 'Genesis'"
