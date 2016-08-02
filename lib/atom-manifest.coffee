{ Point
, View
} = require 'atom'

fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'

module.exports =
    activate: (state) ->
      atom.commands.add 'atom-text-editor',
        'atom-manifest:insert': (event) =>
          @run()

      @messenger = null
      @messages = []

    deactivate: ->
      @messages.map (msg) -> msg.destroy()

    serialize: ->
      return "{}"

    consumeInlineMessenger: (messenger) ->
      @messenger = messenger

    consumeStatusBar: (statusBar) ->
      span = document.createElement('span')
      span.textContent = "SFDsdf"
      @statusBarTile = statusBar.addLeftTile(item: span, priority: 100)

    run: ->
      if @messenger
        editor = atom.workspace.getActiveTextEditor()
        config = yaml.safeLoad(fs.readFileSync(path.join(atom.project.getPaths()[0], 'manifest.yaml')))

        documentRange =  [[0, 0], [editor.getLineCount(), 0]]
        regexSearch = '\\[([^\\]]*)\\]'
        regexFlags = 'g'

        editor.scanInBufferRange new RegExp(regexSearch, regexFlags), documentRange, (result) =>
          configString = result.match[1]
          configRange = result.range

          configRange.start.column += 1
          configRange.end.column -= 1

          value = configString.split('.').reduce(((a, b) ->
            a[b]
          ), config)
          severity = "warning"

          unless value
            value = "No configuration found"
            severity = "error"

          @messages.push @messenger.message
            range: configRange
            text: value
            severity: severity
