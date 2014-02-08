###

  JSON Serializable UI State

###



class UIState
  constructor: (@attributes = @DEFAULTS()) ->
    @on 'change', =>
      @saveLocally()

  restore: ->
    # Restore the previous state in localStorage if it exists
    storedState = localStorage.getItem 'uistate'
    @importJSON(JSON.parse storedState) if storedState?
    @

  set: (key, val) ->
    # Prevent echo loops and pointless change callbacks
    return if @attributes[key] == val
    switch key
      when 'tool'
        @attributes.lastTool = @attributes.tool
        @attributes.tool = val
      else
        @attributes[key] = val

    @trigger 'change', key, val
    @trigger "change:#{key}", val

  get: (key) ->
    @attributes[key]

  saveLocally: ->
    localStorage.setItem('uistate', @toJSON())

  apply: ->
    ui.fill.absorb @get 'fill'
    ui.stroke.absorb @get 'stroke'

  toJSON: ->
    fill:        @attributes.fill.hex
    stroke:      @attributes.stroke.hex
    strokeWidth: @attributes.strokeWidth
    zoom:        @attributes.zoom
    normal:      @attributes.normal.toJSON()
    tool:        @attributes.tool.id
    lastTool:    @attributes.lastTool.id

  importJSON: (attributes) ->
    @attributes =
      fill:        new Color attributes.fill
      stroke:      new Color attributes.stroke
      strokeWidth: attributes.strokeWidth
      zoom:        attributes.zoom
      normal:      Posn.fromJSON(attributes.normal)
      tool:        tools[attributes.tool]
      lastTool:    tools[attributes.lastTool]
    @trigger 'change'

  DEFAULTS: ->
    # These are "pre-parsed"; we don't bother
    # storing this in JSON
    fill:        new Color "#5fcda7"
    stroke:      new Color "#000000"
    strokeWidth: 1.0
    zoom:        1.0
    normal:      new Posn -1, -1
    tool:        tools.cursor
    lastTool:    tools.cursor

$.extend UIState::, mixins.events

window.UIState = UIState
