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
  key 'l, shift+l', ->
    alert('Not implemented!')

  # List navigation
  key 'c, shift+c', -> alert('Not implemented!')
  key 'm, shift+m', -> alert('Not implemented!')
  key 'i, shift+i', -> alert('Not implemented!')
  key 'e, shift+e', -> alert('Not implemented!')

  # Show help
  key 'h, shift+h', ->
    $('#help').toggle()

  # Fuzzy class search
  key 't, shift+t', (e) ->
    e.preventDefault()

    $('#fuzzySearch').toggle()
    $('#fuzzySearch input').focus().select()