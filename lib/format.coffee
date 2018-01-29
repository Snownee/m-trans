module.exports =
class MTransFormatter
  parse: (str, return_error = false) ->
    try
      return JSON.parse(str)
    catch error
      console.error error
      if return_error
        return error
      else
        return false

  format: (str) ->
    json = @parse str
    if json
      return JSON.stringify(json, null, atom.config.get("editor.tabLength"))

  convert: (str) ->
    
