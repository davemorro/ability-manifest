{CompositeDisposable} = require "atom"
AbilityManifestAreaView = require './ability-manifest-area-view'

module.exports =
    config:
        extensions:
            title: 'Autoactivated file extensions'
            description: 'List of file extenstions which should have the Manifest plugin enabled'
            type: 'array'
            default: [ 'feature', 'ability', 'robot' ]
            items:
                type: 'string'
            order: 1
        manifest:
            title: 'Location of manifest file'
            description: 'Include filename and path if not in your project root'
            type: 'string'
            default: 'manifest.yaml'
            order: 2
    activate: (state) ->
        {extensions} = atom.config.get('ability-manifest')
        extensions = (extensions || []).map (extension) -> extension.toLowerCase()
        current_file_extension = buffer?.file?.path.match(/\.(\w+)$/)?[1].toLowerCase()
        if current_file_extension in extensions
            @areaView.disable()
            @deactivate()

        @areaView = new AbilityManifestAreaView()
        @subscriptions = new CompositeDisposable

        @subscriptions.add atom.commands.add "atom-text-editor",
            'ability-manifest:toggle': => @toggle()

    deactivate: ->
        @areaView?.destroy()
        @areaView = null
        @subscriptions?.dispose()
        @subscriptions = null

    consumeInlineMessenger: (messenger) ->
        console.log 'Consume Inline Messenger'
        @areaView.setInlineMessenger(messenger)

    toggle: ->
        if @areaView.disabled
            @areaView.enable()
        else
            @areaView.disable()
