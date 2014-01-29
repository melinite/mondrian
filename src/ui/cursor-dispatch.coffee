  # Event proxies for tools

ui.dispatch =
  hover: (e, target) ->
    e.target = target
    ui.uistate.get('tool').dispatch(e, "hover")
    topUI = isOnTopUI(target)
    if topUI
      switch topUI
        when "menu"
          menus = objectValues(ui.menu.menus)
          # If there's a menu that's open right now
          if menus.filter((menu) -> menu.dropdownOpen).length > 0
            # Get the right menu
            menu = menus.filter((menu) -> menu.itemid is target.id)[0]
            menu.openDropdown() if menu?

  unhover: (e, target) ->
    e.target = target
    ui.uistate.get('tool').dispatch(e, "unhover")

  click: (e, target) ->
    # Certain targets we ignore.
    if (target.nodeName.toLowerCase() is "emph") or (target.hasAttribute("buttontext"))
      t = $(target).closest(".menu-item")[0]
      if not t?
        t = $(target).closest(".menu")[0]
      target = t

    topUI = isOnTopUI(target)

    if topUI
      # Constrain UI to left clicks only.
      return if e.which isnt 1

      switch topUI
        when "menu"
          ui.menu.menu(target.id)?._click(e)

        when "menu-item"
          ui.menu.item(target.id)?._click(e)

        else
          ui.topUI.dispatch(e, "click")
    else
      if e.which is 1
        ui.uistate.get('tool').dispatch(e, "click")
      else if e.which is 3
        ui.uistate.get('tool').dispatch(e, "rightClick")

  doubleclick: (e, target) ->
    ui.uistate.get('tool').dispatch(e, "doubleclick")

  mousemove: (e) ->
    # Paw tool specific shit. Sort of hackish. TODO find a better spot for this.
    topUI = isOnTopUI(e.target)
    if topUI
      ui.topUI.dispatch(e, "mousemove")
    if ui.uistate.get('tool') is tools.paw
      dom.$toolCursorPlaceholder.css
        left: e.clientX - 8
        top: e.clientY - 8

  mousedown: (e) ->
    if not isOnTopUI(e.target)
      ui.menu.closeAllDropdowns()
      ui.refreshUtilities()
      ui.uistate.get('tool').dispatch(e, "mousedown")

  mouseup: (e) ->
    topUI = isOnTopUI(e.target)
    if topUI
      ui.topUI.dispatch(e, "mouseup")
    else
      e.stopPropagation()
      ui.uistate.get('tool').dispatch(e, "mouseup")

  startDrag: (e) ->
    topUI = isOnTopUI(e.target)
    if topUI
      ui.topUI.dispatch(e, "startDrag")
    else
      ui.uistate.get('tool').initialDragPosn = new Posn e
      ui.uistate.get('tool').dispatch(e, "startDrag")

      for key in ui.hotkeys.modifiersDown
        ui.uistate.get('tool').activateModifier(key)

  continueDrag: (e, target) ->
    e.target = target
    topUI = isOnTopUI(target)
    if topUI
      ui.topUI.dispatch(e, "continueDrag")
    else
      ui.uistate.get('tool').dispatch(e, "continueDrag")

  stopDrag: (e, target) ->
    document.onselectstart = -> true

    releaseTarget = e.target
    e.target = target
    topUI = isOnTopUI(e.target)

    if topUI
      if (target.nodeName.toLowerCase() is "emph") or (target.hasAttribute("buttontext"))
        target = target.parentNode

      switch topUI
        when "menu"
          if releaseTarget is target
            ui.menu.menu(target.id)?._click(e)
        when "menu-item"
          if releaseTarget is target
            ui.menu.item(target.id)?._click(e)

        else
          ui.topUI.dispatch(e, "stopDrag")
    else
      ui.uistate.get('tool').dispatch(e, "stopDrag")
      ui.uistate.get('tool').initialDragPosn = null
      ui.snap.toNothing()



