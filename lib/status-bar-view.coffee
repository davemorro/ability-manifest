module.exports =
class StatusBarView
  constructor: ->
    @element = document.createElement 'div'
    @element.classList.add("highlight-selected-status","inline-block")

  updateValue: (value) ->
    @element.textContent = "Value: " + value
    if value == ""
      @element.classList.add("highlight-selected-hidden")
    else
      @element.classList.remove("highlight-selected-hidden")

  getElement: =>
    @element

  removeElement: =>
    @element.parentNode.removeChild(@element)
    @element = null
