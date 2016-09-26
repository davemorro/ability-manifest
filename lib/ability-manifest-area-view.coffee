{ CompositeDisposable,
  Point,
  View
} = require 'atom'

fs   = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
_    = require 'lodash'

module.exports =
class AbilityManifestAreaView
    constructor: ->
        console.log 'activate'
        @views = []
        @messages = []
        @messenger = null
        @manifest = null
        @locale = null

        @enable()
        #@listenForTimeoutChange()
        @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
            @subscribeToActiveTextEditor()

    destroy: =>
        @activeItemSubscription.dispose()
        @editorSubscription?.dispose()
        #clearTimeout(@handleSelectionTimeout)

    disable: =>
        @disabled = true
        #@removeMarkers()

    enable: =>
        @disabled = false
        #@debouncedHandleSelection()

    subscribeToActiveTextEditor: ->
        @editorSubscription?.dispose()
        return unless @getActiveEditor()

        @editorSubscription = new CompositeDisposable
        @editorSubscription = @getActiveEditor().onDidStopChanging =>
            @setupMessages()

        @loadConfigs() if @messenger

    getActiveEditor: ->
        atom.workspace.getActiveTextEditor()

    getActiveEditors: ->
        atom.workspace.getPanes().map (pane) ->
            activeItem = pane.activeItem
            activeItem if activeItem and activeItem.constructor.name == 'TextEditor'

    #handleSelection: ->

        # if current_file_extension in extensions
        #     @active = false
        # self = this
        # atom.workspace.observeTextEditors (editor) ->
        #     #editor.onDidChange self.run()
        #     editor.onDidStopChanging self.run()

    deactivate: ->
        @messages.map (msg) -> msg.destroy()
        @subscriptions?.dispose()
        @subscriptions = null

    serialize: ->
        return "{}"

    # consumeStatusBar: (statusBar) ->
    #     span = document.createElement('span')
    #     span.textContent = "SFDsdf"
    #     @statusBarTile = statusBar.addLeftTile(item: span, priority: 100)

    setInlineMessenger: (messenger) =>
        @messenger = messenger
        @loadConfigs()

    loadConfigs: =>
      @loadManifest()
      @loadLocale()

    loadManifest: ->
        {manifest} = atom.config.get('ability-manifest')
        @loadConfig(manifest)

    loadLocale: ->
        {locale} = atom.config.get('ability-manifest')
        @loadConfig(locale)

    loadConfig: (configPath) ->
      file = path.join(atom.project.getPaths()[0], configPath)
      self = this
      fs.stat file, (err, stat) ->
          if err == null # file exists
              # TODO: Update for callback
              if configPath == 'manifest.yaml'
                self.manifest = yaml.safeLoad(fs.readFileSync(file))
              else if configPath == '_locales/en.yaml'
                self.locale = yaml.safeLoad(fs.readFileSync(file))
              self.setupMessages()
          else
              return null

    setupMessages: ->
        editor = @getActiveEditor()
        return unless editor
        return unless @messenger
        return unless @manifest

        @messages.map (msg) -> msg.destroy()
        @messages = []

        documentRange =  [[0, 0], [editor.getLineCount(), 0]]
        regexSearch = '\\[([^\\]]*)\\]'
        regexFlags = 'g'

        editor.scanInBufferRange new RegExp(regexSearch, regexFlags), documentRange, (result) =>
            configString = result.match[1]
            configRange = result.range

            configRange.start.column += 1
            configRange.end.column -= 1

            # this isn't particularly elegant
            try
                value = configString.split('.').reduce(((a, b) ->
                    a[b]
                ), @manifest)
                severity = "info"

                throw "Not found" unless value

            catch err
                value = "No manifest value found"
                severity = "error"

            # unless value
            #     value = "No manifest value found"
            #     severity = "error"

            if value.constructor == Array
                if value.length > 20
                    value = value.slice(0,19)
                    value.push "..."
                value = value.join("\n")

            @messages.push @messenger.message
                range: configRange
                text: value
                severity: severity

        regexSearch = 't\\(([^\\)]*)\\)'
        regexFlags = 'g'

        editor.scanInBufferRange new RegExp(regexSearch, regexFlags), documentRange, (result) =>
            configString = result.match[1]
            configRange = result.range

            configRange.start.column += 2
            configRange.end.column -= 1

            # this isn't particularly elegant
            try
                value = configString.split('.').reduce(((a, b) ->
                    a[b]
                ), @locale)
                severity = "info"

                throw "Not found" unless value

            catch err
                value = "No locale entry found"
                severity = "error"

            # unless value
            #     value = "No manifest value found"
            #     severity = "error"

            if value.constructor == Array
                if value.length > 20
                    value = value.slice(0,19)
                    value.push "..."
                value = value.join("\n")

            @messages.push @messenger.message
                range: configRange
                text: value
                severity: severity
