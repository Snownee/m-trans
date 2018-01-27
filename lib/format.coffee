module.exports =
class MTransFormatter
  check: (str) ->
    try
      return JSON.parse(str)
    catch error
      return false

  format: (str) ->
    json = @check str
    if json
      return require('util').inspect(json)
