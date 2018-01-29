path = require 'path'
fs = require 'fs-plus'
Dialog = require './dialog'
# {repoForPath} = require './helpers'

module.exports =
class AddDialog extends Dialog
  constructor: (initialPath) ->

    # if fs.isFileSync(initialPath)
    #   directoryPath = path.dirname(initialPath)
    # else
    #   directoryPath = initialPath

    relativeDirectoryPath = initialPath
    [@rootProjectPath, relativeDirectoryPath] = atom.project.relativizePath(initialPath)
    # console.log relativeDirectoryPath, path.sep
    # relativeDirectoryPath += path.sep if relativeDirectoryPath.length > 0

    super
      prompt: "Enter the path for the new file."
      initialPath: relativeDirectoryPath
      select: true
      iconClass: 'icon-file-add'

  onDidCreateFile: (callback) ->
    @emitter.on('did-create-file', callback)

  onConfirm: (newPath) ->
    newPath = newPath.replace(/\s+$/, '') # Remove trailing whitespace
    endsWithDirectorySeparator = newPath[newPath.length - 1] is path.sep
    unless path.isAbsolute(newPath)
      unless @rootProjectPath?
        @showError("You must open a directory to create a file with a relative path")
        return

      newPath = path.join(@rootProjectPath, newPath)

    return unless newPath

    try
      if fs.existsSync(newPath)
        @showError("'#{newPath}' already exists.")
      else
        if endsWithDirectorySeparator
          @showError("File names must not end with a '#{path.sep}' character.")
        else
          fs.writeFileSync(newPath, '')
          # repoForPath(newPath)?.getPathStatus(newPath)
          @emitter.emit('did-create-file', newPath)
          @close()
    catch error
      @showError("#{error.message}.")
