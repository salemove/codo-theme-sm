$ ->
  openList = (klass) ->
    $('.toggled').removeClass('visible')
    $(".toggled.#{klass}").addClass('visible')

  window.openClassList = -> openList('class_list')
  window.openMethodList = -> openList('method_list')
  window.openMixinList = -> openList('mixin_list')
  window.openExtraList = -> openList('extra_list')

  # Create stripes
  window.createStripes = ->
    $('.list li').each (i, el) ->
      if i % 2 is 0 then $(el).addClass('stripe') else $(el).removeClass('stripe')

  # Indent nested Lists
  window.indentTree = (el, width) ->
    $(el).find('> ul').each ->
      $(@).find('> li').css 'padding-left', "#{ width }px"
      window.indentTree $(@), width + 20


  #
  # Add tree arrow links
  #
  $('.tree ul > ul').each ->
    $(@).prev().prepend $('<a href="#" class="toggle"></a>')

  #
  # Search List
  #
  $('#search input').keyup (event) ->
    search = $(@).val().toLowerCase()

    if search.length == 0
      $('.list ul li').each ->
        if $('.list').hasClass 'tree'
          $(@).removeClass 'result'
          $(@).css 'padding-left', $(@).data 'padding'
        $(@).show()
    else
      $('.list ul li').each ->
        if $(@).find('a').text().toLowerCase().indexOf(search) == -1
          $(@).hide()
        else
          if $('.list').hasClass 'tree'
            $(@).addClass 'result'
            padding = $(@).css('padding-left')
            $(@).data 'padding', padding unless padding == '0px'
            $(@).css 'padding-left', 0
          $(@).show()

    window.createStripes()

  #
  # Collapse/expand sub trees
  #
  $('.tree a.toggle').click ->
    $(@).toggleClass 'collapsed'
    $(@).parent().next().toggle()
    window.createStripes()

  #
  # Initialize
  #
  indentTree $('.list > ul'), 20
  createStripes()