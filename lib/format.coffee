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

  format: (jsonData = "") ->
    if (typeof jsonData) is 'string'
      jsonData = @parse jsonData
    if jsonData
      return JSON.stringify(jsonData, null, atom.config.get("editor.tabLength"))

  convert: (str) ->
    list = str.replace(/\r/g, '').split('\n')
    o = {}
    count = [0, 0]
    for line in list
      if /^[ a-zA-Z0-9_:.\\-][ #a-zA-Z0-9_:.\\-]*\s*=.+$/.test(line)
        key = line.slice(0, line.indexOf('='))
        key = key.replace(/^tile\./, 'block.')
        key = key.replace(/\.name$/, '')
        value = line.slice(line.indexOf('=') + 1, line.length)
        if o[key]?
          count[1]++
          continue
        o[key] = value
        count[0]++
      else
        count[1]++
    return [o, count]
