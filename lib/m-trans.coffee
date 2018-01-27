http = require 'http'
$ = require 'jquery'

MTransView = require './m-trans-view'
MTransFormatter = require './format'
{CompositeDisposable} = require 'atom'

HTMLsanitize = (str) ->
  return str.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

module.exports = MTrans =
  mTransView: null
  mTransFormatter: new MTransFormatter
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @mTransView = new MTransView(state.mTransViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @mTransView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-pane', 'm-trans:select-prev-entry', (e) =>
        @selectPrev(e)
    @subscriptions.add atom.commands.add 'atom-pane', 'm-trans:select-next-entry', (e) =>
        @selectNext(e)
    @subscriptions.add atom.commands.add 'atom-pane', 'm-trans:show-trans', (e) =>
        @showTrans(e)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'm-trans:word-move-up', (e) =>
        @wordMove(e)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'm-trans:word-move-down', (e) =>
        @wordMove(e)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'm-trans:word-move-left', (e) =>
        @wordMove(e)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'm-trans:word-move-right', (e) =>
        @wordMove(e)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'm-trans:word-select', (e) =>
        @wordMove(e)

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @mTransView.destroy()

  serialize: ->
    mTransViewState: @mTransView.serialize()

  selectNext: (e) ->
    editor = atom.workspace.getActiveTextEditor()
    point = editor.getCursorBufferPosition()
    grammar = editor.getGrammar().scopeName
    unless (grammar is 'source.lang' or grammar is 'source.json') and point.row + 1 isnt editor.getLineCount
      e.abortKeyBinding()
      return

    @select editor, e, point.row + 1, grammar

  selectPrev: (e) ->
    editor = atom.workspace.getActiveTextEditor()
    point = editor.getCursorBufferPosition()
    grammar = editor.getGrammar().scopeName

    unless (grammar is 'source.lang' or grammar is 'source.json') and point.row isnt 0
      e.abortKeyBinding()
      return

    @select editor, e, point.row - 1, grammar

  select: (editor, e, row, grammar) ->
    str = editor.getBuffer().lineForRow(row)
    if grammar is 'source.lang'
      unless /^[ #a-zA-Z0-9_:.\\-]+\s*=.+$/.test(str)
        e.abortKeyBinding()
        return
      range = [[row, str.indexOf('=') + 1], [row, str.length]]
    else if grammar is 'source.json'
      matches = str.match(/^\s*('|")[ #a-zA-Z0-9_:.\\-]+?\1\s*:\s*('|")(.*)\2\s*,?\s*$/)
      unless matches
        e.abortKeyBinding()
        return
      pos = str.indexOf(matches[1])
      pos = str.indexOf(matches[1], pos + 1)
      pos = str.indexOf(':', pos + 1)
      pos = str.indexOf(matches[2], pos + 1)
      range = [[row, pos + 1], [row, pos + 1 + matches[3].length]]
    else
      range = [[row, 0], [row, str.length]]

    editor.setSelectedBufferRange(range)
    @showTrans {} if atom.config.get('mTrans:autoQuery')

  showTrans: (e) ->
    if @modalPanel.isVisible()
      @modalPanel.hide()
      return

    editor = atom.workspace.getActiveTextEditor()
    word = editor.getSelectedText()
    if word.length is 0
      @select editor, { abortKeyBinding: -> }, editor.getCursorBufferPosition().row, editor.getGrammar().scopeName
      word = editor.getSelectedText()
      return if word.length is 0

    @getYoudao word, @gotIt, @mTransView.getElement()
    @modalPanel.show()

  getYoudao: (lookup, callback, element) =>
    data = ''
    lookup = encodeURI(lookup, callback)
    options =
      host: 'fanyi.youdao.com'
      path: '/openapi.do?keyfrom=atom-trans-en-zh&key=769450225&type=data&doctype=json&version=1.1&q='+lookup
    req = http.get options, (res) ->
      res.on 'data', (chunk) ->
        data += chunk
      res.on 'end', () ->
        callback data, element
    req.on "error", (e) ->
      console.log "Erorr: {e.message}"

  gotIt: (data, element) ->
    jsonData = JSON.parse data
    if jsonData.errorCode is 0
      element.children[0].innerHTML = HTMLsanitize(jsonData.query)
      pronounce = ''
      # 如果包含中文 或 长句翻译
      if jsonData.query.match(/[\u4e00-\u9fa5]/) isnt null or !jsonData.basic?
        explains = "<div class=\"trans\"><span class=\"selected\">#{HTMLsanitize(jsonData.translation[0])}</span></div>"
      else
        explains = "<div class=\"trans\">1. <span class=\"selected\">#{HTMLsanitize(jsonData.translation[0])}</span></div>"
      webexplains = '<div class="webexplains">网络释义</div>'
      if jsonData.basic isnt undefined
        if jsonData.basic['uk-phonetic']?
          pronounce += '英 [' + jsonData.basic['uk-phonetic'] + ']    '
        if jsonData.basic['us-phonetic']?
          pronounce += '美 [' + jsonData.basic['us-phonetic'] + ']    '
        else if jsonData.basic.phonetic?
          pronounce = '[' + jsonData.basic['phonetic'] + ']'
        pronounce = '<div class="pronounce">' + pronounce + '</div>'
        if jsonData.basic.explains?
          if jsonData.query.match(/[\u4e00-\u9fa5]/) isnt null
            explains += "<div class=\"trans\"><span>#{i}</span></div>" for i in jsonData.basic.explains
          else
            for i in [1..jsonData.basic.explains.length]
              matches = jsonData.basic.explains[i-1].match(/^[a-z]{1,4}\.\s/)
              explains += '<div class="trans">' + (matches || "")
              list = jsonData.basic.explains[i-1].split(/；|[a-z]{1,4}\.\s/)
              matches = if matches then 1 else 0
              for j in [matches..list.length-1]
                explains += "<span>#{list[j]}</span>；"
              explains += '</div>'

      element.children[1].innerHTML = pronounce
      element.children[2].innerHTML = explains
      $(element).find('.trans>span').click (e) ->
        atom.workspace.getActiveTextEditor().insertText $(@).text()
        atom.workspace.panelForItem(element).hide()

      if jsonData.web?
        for item in jsonData.web
          webexplains += item.key + ' : '
          for j in item.value
            webexplains += j + '  '
          webexplains += '<br />'
      element.children[3].innerHTML = '<hr />' + webexplains
      return

    if jsonData.errorCode is 20
      element.children[0].innerHTML = '要翻译的文本过长'
    if jsonData.errorCode is 30
      element.children[0].innerHTML = '无法进行有效的翻译'
    if jsonData.errorCode is 40
      element.children[0].innerHTML = '不支持的语言类型'
    if jsonData.errorCode is 50
      element.children[0].innerHTML = '无效的key'
    if jsonData.errorCode is 60
      element.children[0].innerHTML = '无词典结果，仅在获取词典结果生效'

    element.children[1].innerHTML = ''
    element.children[2].innerHTML = ''
    element.children[3].innerHTML = ''

  wordMove: (e) ->
    unless @modalPanel.isVisible()
      e.abortKeyBinding()
      return
    el = $('.m-trans .trans>.selected')
    return if el.length isnt 1
    switch e.type
      when 'm-trans:word-move-up'
        if !el.parent().is('.trans:first-child')
          el.removeClass('selected')
          el.parent().prev().children('span:last-child').addClass('selected')

      when 'm-trans:word-move-down'
        el.removeClass('selected')
        if el.parent().is('.trans:last-child')
          el.parent().children('span:last-child').addClass('selected')
        else
          el.parent().next().children('span:first-child').addClass('selected')

      when 'm-trans:word-move-left'
        if !el.is('span:first-child')
          el.prev().addClass('selected')
          el.removeClass('selected')

      when 'm-trans:word-move-right'
        if !el.is('span:last-child')
          el.next().addClass('selected')
          el.removeClass('selected')

      when 'm-trans:word-select'
        str = el.text().match(/[^\]\)]+$/)
        str = el.text().match(/[^\]]+$/) if not str
        atom.workspace.getActiveTextEditor().insertText str[0]
        @modalPanel.hide()
