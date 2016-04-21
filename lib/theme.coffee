strftime    = require 'strftime'
FS          = require 'fs'
Path        = require 'path'
Templater   = require './templater'
TreeBuilder = require './tree_builder'

Theme = require './_theme'
Codo  = require 'codo'

module.exports = class Theme.Theme

  options: [
    {name: 'private', alias: 'p', describe: 'Show privates', boolean: true, default: false}
    {name: 'analytics', alias: 'a', describe: 'The Google analytics ID', default: false}
    {name: 'title', alias: 't', describe: 'HTML Title', default: 'CoffeeScript API Documentation'}
  ]

  @compile: (environment) ->
    theme = new @(environment)
    theme.compile()

  constructor: (@environment) ->
    @templater  = new Templater(@environment.options.output)
    @referencer = new Codo.Tools.Referencer(@environment)

  compile: ->
    @templater.compileAsset('javascript/application.js')
    @templater.compileAsset('stylesheets/application.css')

    @renderAlphabeticalIndex()
    @render 'method_list', 'method_list.html'

    @renderClasses()
    @renderMixins()
    @renderExtras()
    @renderIndex()
    @renderFuzzySearchData()

  #
  # HELPERS
  #
  awareOf: (needle) ->
    @environment.references[needle]?

  reference: (needle, prefix) ->
    @pathFor(@environment.reference(needle), undefined, prefix)

  anchorFor: (entity) ->
    if entity?.constructor.name == "Method"
      "#{entity.name}-#{entity.kind}"
    else if entity?.constructor.name == "Property"
      "#{entity.name}-property"
    else if entity?.constructor.name == "Variable"
      "#{entity.name}-variable"

  pathFor: (kind, entity, prefix='') ->
    unless entity?
      entity = kind
      kind = 'class'  if entity.constructor.name == "Class"
      kind = 'mixin'  if entity.constructor.name == "Mixin"
      kind = 'file'   if entity.constructor.name == "File"
      kind = 'extra'  if entity.constructor.name == "Extra"
      kind = 'method' if entity.entity?.constructor.name == "Method"
      kind = 'variable' if entity.entity?.constructor.name == "Variable"
      kind = 'property' if entity.entity?.constructor.name == "Property"

    switch kind
      when 'file', 'extra'
        prefix + kind + '/' + entity.name + '.html'
      when 'class', 'mixin'
        prefix + kind + '/' + entity.name.replace(/\./, '/') + '.html'
      when 'method', 'variable'
        @pathFor(entity.owner, undefined, prefix) + '#' + @anchorFor(entity.entity)
      else
        entity

  activate: (text, prefix, limit=false) ->
    text = @referencer.resolve text, (link, label) =>
      "<a href='#{@pathFor link, undefined, prefix}'>#{label}</a>"

    Codo.Tools.Markdown.convert(text, limit)

  generateBreadcrumbs: (entries = []) ->
    entries     = [entries] unless Array.isArray(entries)
    breadcrumbs = []

    if @environment.options.readme
      breadcrumbs.push
        href:  @pathFor('extra', @environment.findReadme())
        title: @environment.options.name

    breadcrumbs.push(href: 'alphabetical_index.html', title: 'Index')

    for entry in entries
      if entry instanceof Object
        breadcrumbs.push entry
      else
        breadcrumbs.push {title: entry}

    breadcrumbs

  calculatePath: (filename) ->
    dirname = Path.dirname(filename)
    dirname.split(/[\/\\]/).map(-> '..').join('/')+'/' unless dirname == '.'

  render: (source, destination, context={}) ->
    globalContext =
      environment: @environment
      path:        @calculatePath(destination)
      strftime:    strftime
      anchorFor:   @anchorFor
      pathFor:     @pathFor
      reference:   @reference
      awareOf:     @awareOf
      activate:    => @activate(arguments...)
      render:      (template, context={}) =>
        context[key] = value for key, value of globalContext
        @templater.render template, context

    context[key] = value for key, value of globalContext
    @templater.render source, context, destination

  #
  # RENDERERS
  #

  # Generate the alphabetical index of all classes and mixins.
  #
  renderAlphabeticalIndex: ->
    classes = {}
    mixins  = {}

    # Sort in character group
    for code in [97..122]
      char = String.fromCharCode(code)
      map  = [
        [@environment.visibleClasses(), classes],
        [@environment.visibleMixins(), mixins],
      ]

      for [list, storage] in map
        for entry in list
          if entry.basename.toLowerCase()[0] == char
            storage[char] ?= []
            storage[char].push(entry) 

    @render 'alphabetical_index', 'alphabetical_index.html',
      classes: classes
      mixins:  mixins

  renderIndex: ->
    list = if @environment.visibleClasses().length > 0
        'class_list.html'
      else if @environment.visibleMixins().length > 0
        'mixin_list.html'
      else if @environment.visibleExtras().length > 0
        'extra_list.html'
      else
        'method_list.html'

    main = if @environment.options.readme
      @pathFor('extra', @environment.findReadme())
    else
      'alphabetical_index.html'

    @render 'frames', 'index.html',
      list: list
      main: main

  renderClasses: ->
    @render 'class_list', 'class_list.html',
      tree: TreeBuilder.build @environment.visibleClasses(), (klass) ->
        [klass.basename, klass.namespace.split('.')]

    for klass in @environment.visibleClasses()
      @render 'class', @pathFor('class', klass),
        entity: klass,
        breadcrumbs: @generateBreadcrumbs(klass.name.split '.')

  renderMixins: ->
    @render 'mixin_list', 'mixin_list.html',
      tree: TreeBuilder.build @environment.visibleMixins(), (klass) ->
        [klass.basename, klass.namespace.split('.')]

    for mixin in @environment.visibleMixins()
      @render 'mixin', @pathFor('mixin', mixin),
        entity: mixin
        breadcrumbs: @generateBreadcrumbs(mixin.name.split '.')

  renderExtras: ->
    @render 'extra_list', 'extra_list.html',
      tree: TreeBuilder.build @environment.visibleExtras(), (extra) ->
        result = extra.name.split('/')
        [result.pop(), result]

    for extra in @environment.visibleExtras()
      @render 'extra', @pathFor('extra', extra),
        entity: extra
        breadcrumbs: @generateBreadcrumbs(extra.name.split '/')

  renderFuzzySearchData: ->
    search = []
    everything = [
      @environment.visibleClasses(),
      @environment.visibleMixins(),
      @environment.visibleExtras()
    ]

    for basics in everything
      for basic in basics
        search.push
          t: basic.name
          p: @pathFor(basic)

    for method in @environment.visibleMethods()
      search.push
        t: "#{method.owner.name}#{method.entity.shortSignature()}"
        p: @pathFor(method)

    content = 'window.searchData = ' + JSON.stringify(search)
    output  = Path.join(@environment.options.output, 'javascript', 'search.js')

    FS.writeFileSync output, content