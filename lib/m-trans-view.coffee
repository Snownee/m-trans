module.exports =
class MTransView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('m-trans')

    # Create translate result elements
    query = document.createElement('div')
    query.classList.add('query')
    @element.appendChild(query)

    pronounce = document.createElement('div')
    pronounce.classList.add('pronounce')
    @element.appendChild(pronounce)

    basic = document.createElement('div')
    basic.classList.add('basic')
    @element.appendChild(basic)

    web = document.createElement('div')
    web.classList.add('web')
    @element.appendChild(web)

    # @element.on

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
