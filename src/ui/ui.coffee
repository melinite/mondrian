###

  UI handling

  Handles
    - Mouse event routing
    - UI state memory
  Core UI functions and interface for all events used by the tools.


###


window.ui =
  # This is the highest level of UI in Mondy.
  # It contains lots of more specific objects and dispatches events to tools
  # as appropriate. It also handles tool switching.
  #
  # It has many child objects with more specific functions, like hotkeys and cursor (tracking)

  setup: ->
    # Default settings for a new Mondrian session.

    @uistate = new UIState()
    @uistate.restore()

    # This means the user switched tabs and came back.
    # Now we have no idea where the cursor is,
    # so don't even try showing the placeholder if it's up.
    ui.window.on 'focus', =>
      dom.$toolCursorPlaceholder.hide()

    # Make sure the window isn't somehow scrolled. This will hide all the UI, happens very rarely.
    window.scrollTo 0, 0

    # Base case for tool switching.
    #@lastTool = tools.cursor

    # Set the default fill and stroke colors in case none are stored in localStorage
    @fill = new Swatch("5fcda7").appendTo("#fill-color")
    @stroke = new Swatch("000000").appendTo("#stroke-color")

    @fill.type = "fill"
    @stroke.type = "stroke"

    # The default UI config is the draw config obviously!
    @changeTo "draw"

    @selection.elements.on 'change', =>
      @refreshUtilities()
      @transformer.refresh()
      @utilities.transform.refresh()


  clear: ->
    $("#ui .point.handle").remove()


  new: (width, height, normal = @canvas.normal, zoom = @canvas.zoom) ->
    # Set up the UI for a new file. Give two dimensions.
    # TODO Add a user interface for specifying file dimensions
    @canvas.width = width
    @canvas.height = height
    @canvas.zoom = zoom
    @canvas.normal = normal
    @canvas.redraw()
    @canvas.zoom100()
    @deleteAll()


  configurations:
    # A configuration is defined as an function that returns an object.
    # The object needs to have a "show" attribute which is an array
    # of elements to show when we choose that UI configuration.
    # Before this is done, the previous configuration's "show"
    # elements are hidden. This lets us toggle easily between UI modes, like
    # going from draw mode to save mode for example.
    #
    # A configuration can also have an "etc" function which will just run
    # with no parameters when the configuration is selected.
    draw: ->
      show:
        [dom.$canvas
        dom.$toolPalette
        dom.$menuBar
        dom.$filename
        dom.$currentSwatches
        dom.$utilities]
    gallery: ->
      show:
        [dom.$currentService
        dom.$serviceGallery]
    browser: ->
      show:
        [dom.$currentService
        dom.$serviceBrowser]


  changeTo: (config) ->
    # Hide the old config
    @currentConfig?.show.map (e) -> e.hide()

    # When we switch contexts we want to get hotkeys back immediately,
    # becuase it's pretty much guaranteed that whatever
    # might have disabled them before is now gone.
    @hotkeys.enable().reset()

    if "config" is "draw"
      @refreshUtilities()
    else
      for util in @utilities
        util.hide()

    @currentConfig = @configurations[config]?()
    if @currentConfig?
      @currentConfig.show.map (e) -> e.show()
      @currentConfig.etc?()

      # Set the title if we want one.
      if @currentConfig.title?
        dom.$dialogTitle.show().text(@currentConfig.title)
      else
        dom.$dialogTitle.hide()

    @menu.closeAllDropdowns()

    @

  refreshAfterZoom: ->
    for elem in @elements
      elem.refreshUI()
    @selection.points.show()
    @grid.refreshRadii()


  # Tool switching/management

  switchToTool: (tool) ->
    return if tool is @uistate.get('tool')

    @uistate.get('tool')?.tearDown()
    @uistate.set 'tool', tool

    dom.$toolCursorPlaceholder?.hide()
    dom.$body?.off('mousemove.tool-placeholder')
    dom.body?.setAttribute 'tool', tool.cssid

    tool.setup()

    if tool isnt tools.paw
      # All tools except paw (panning; space-bar) have a button
      # in the UI. Update those buttons unless we're just temporarily
      # activating the paw.
      q(".tool-button[selected]")?.removeAttribute('selected')
      q("##{tool.id}-btn")?.setAttribute('selected', '')

      # A hack, somewhat. Changing the document cursor offset in the CSS
      # fires a mousemove so if we're changing to a tool with a different
      # action point then it's gonna disappear. But the mousemove event object
      # has an offsetX, offsetY attribute pair which will match the tool's
      # own offsetX and offsetY, so we just take the first event where those
      # don't match and hide the placeholder.
      dom.$body.on('mousemove.tool-placeholder', (e) =>
        if (e.offsetX != tool.offsetX) or (e.offsetY != tool.offsetY)
          dom.$toolCursorPlaceholder.hide()
          dom.$body.off('mousemove.tool-placeholder'))

    @refreshUtilities()

    return if @cursor.currentPosn is undefined

    dom.$toolCursorPlaceholder
      .show()
      .attr('tool', tool.cssid)
      .css
        left: @cursor.currentPosn.x - tool.offsetX
        top:  @cursor.currentPosn.y - tool.offsetY


  switchToLastTool: ->
    @switchToTool @uistate.get 'lastTool'


  # Colorz

  fill: null

  stroke: null

  # The elements on the board
  elements: [] # Elements on the board

  queryElement: (svgelem) ->
    # I/P: an SVG element in the DOM
    # O/P: its respective Monsvg object
    for elem in @elements
      if elem.rep is svgelem
        return elem


  # TODO Abstract
  hoverTargetsHighlighted: []

  # TODO Abstract
  unhighlightHoverTargets: ->
    for hoverTarget in @hoverTargetsHighlighted
      hoverTarget.unhighlight()
    @hoverTargetsHighlighted = []


  refreshUtilities: ->
    return if not appLoaded
    for own key, utility of @utilities
      if not utility.shouldBeOpen()
        utility.hide()
      else
        utility.show()


  deleteAll: ->
    for elem in @elements
      elem.delete()
    @elements = []
    dom.main.removeChildren()
    @selection.refresh()


  # Common colors
  colors:
    transparent: new Color(0,0,0,0)
    white:  new Color(255, 255, 255)
    black:  new Color(0, 0, 0)
    red:    new Color(255, 0, 0)
    yellow: new Color(255, 255, 0)
    green:  new Color(0, 255, 0)
    teal:   new Color(0, 255, 255)
    blue:   new Color(0, 0, 255)
    pink:   new Color(255, 0, 255)
    null:   new Color(null, null, null)
    # Logo colors
    logoRed:    new Color "#E03F4A"
    logoYellow: new Color "#F1CF2E"
    logoBlue:   new Color "#3FB2E0"


setup.push -> ui.setup()
