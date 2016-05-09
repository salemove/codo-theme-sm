$ ->

  # Allow ESC to blur #search
  key.filter = (e) ->
    tagname = (e.target || e.srcElement).tagName
    tagname isnt 'INPUT' || e.keyCode is 27 || e.ctrlKey is true

  # Focus search input
  key 's, shift+s', (e) ->
    e.preventDefault()

    $('#search input').focus().select()

  # Unblur the search input
  key 'esc', ->
    $('#search input').blur()
    $('#help').hide()
    $('#fuzzySearch').hide()

  # Hide list navigation
  SIDEBAR_HIDDEN_KEY = 'sidebar_hidden'
  HIDE_SIDEBAR_CLASS = 'sidebar_hidden'
  key 'l, shift+l', ->
    if $('body').hasClass(HIDE_SIDEBAR_CLASS)
      $('body').removeClass(HIDE_SIDEBAR_CLASS)
      sessionStorage.removeItem(SIDEBAR_HIDDEN_KEY)
    else
      $('body').addClass(HIDE_SIDEBAR_CLASS)
      sessionStorage.setItem(SIDEBAR_HIDDEN_KEY, 'true')

  # Restore most recent list visibility state on page load
  if sessionStorage.getItem(SIDEBAR_HIDDEN_KEY)?
    $('body').addClass(HIDE_SIDEBAR_CLASS)

  # List navigation
  key 'c, shift+c', window.openClassList
  key 'm, shift+m', window.openMethodList
  key 'i, shift+i', window.openMixinList
  key 'e, shift+e', window.openExtraList

  # Show help
  key 'h, shift+h', ->
    $('#help').toggle()

  # Fuzzy class search
  key 't, shift+t', (e) ->
    e.preventDefault()

    $('#fuzzySearch').toggle()
    $('#fuzzySearch input').focus().select()