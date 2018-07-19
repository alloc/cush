snipSyntaxError = require '../utils/snipSyntaxError'
ErrorTracer = require '../utils/ErrorTracer'
mapSources = require '../utils/mapSources'
getModule = require '../utils/getModule'
elaps = require 'elaps'
path = require 'path'
log = require('lodge').debug('cush')
fs = require 'saxon'
vm = require 'vm'

class Bundle
  constructor: (props) ->
    @id = props.id
    @dev = props.dev
    @root = props.root
    @target = props.target
    @packages = {}
    @_events = {}
    @_config = props.config
    @_timers = {}
    @_loadTime = elaps.lazy()
    @_assetsLoaded = 0
    @_configure props

  relative: (filename) ->
    filename.slice @root.length + 1

  # The "transform" phase occurs after reading the asset.
  transform: (exts, fn) ->

    hook = (asset, pack) ->
      result = fn asset, pack
      if result and result.map
        mapSources asset, result
      return

    hook.source = @_getSource(1)
    if Array.isArray exts
      exts.forEach (ext) => @hook 'asset' + ext, hook
    else @hook 'asset' + exts, hook

  _configure: ({ plugins, parsers }) ->

    parsers.forEach (filename) =>
      for ext, parse of require(filename)
        parse.source = {path: filename}
        @hook 'parse' + ext, parse
      return

    for plugin in plugins
      plugin =
        if plugin.func
        then wrapPlugin(plugin).call this
        else require plugin.path
      plugin.call this
    return

  # Run hooks for a module.
  _loadAsset: (name, root) ->
    t1 = @_loadTime.start()

    if !pack = @packages[root]
      t2 = elaps 'load package %O', @relative(root)
      @packages[root] = pack =
        JSON.parse await fs.read path.join(root, 'package.json')
      pack.path = root
      if event = @_events.package
        await Promise.all event.hooks.map (hook) -> hook pack
      t2.stop()

    t2 = elaps 'load asset %O', @relative(path.join root, name)
    asset =
      ext: path.extname(name)
      path: assetPath = path.join(root, name)
      content: await fs.read(assetPath)
      deps: null
      map: null

    try while asset.ext != ext
      ext = asset.ext
      break if !event = @_events['asset' + ext]
      for hook in event.hooks
        lap = @_timedHook(hook).start()
        await hook asset, pack
        lap.stop()
        break if asset.ext != ext

    catch err
      if err.line?
        ErrorTracer(asset)(err, @relative asset.path)
        err.snippet = snipSyntaxError(asset.content, err)
      throw err

    if event = @_events['parse' + ext]
      for hook in event.hooks
        lap = @_timedHook(hook).start()
        await hook asset, pack
        lap.stop()

    @_assetsLoaded++
    t2.stop()
    t1.stop()

    ext: asset.ext
    content: asset.content
    deps: asset.deps
    map: asset.map

  _timedHook: (hook) ->
    @_timers[hook.source.path] or=
      elaps.lazy 'hook %O', path.relative('', hook.source.path)

  _printStats: ->
    log ''
    log 'worker #' + process.env.WORKER_ID
    log 'assets loaded:', @_assetsLoaded
    @_loadTime.print 'time spent loading: %t'
    for id, timer of @_timers
      timer.print()

    @_assetsLoaded = 0
    @_loadTime.reset()
    @_timers = {}
    return

require('../Bundle/PluginMixin')(Bundle)
module.exports = Bundle

wrapPlugin = (plugin) ->
  ctx = {}

  if plugin.path
    module = getModule(plugin.path)
    ctx.require = (id) -> module.require id
  else
    ctx.require = require

  script = "function plugin() {return #{plugin.func}}"
  vm.runInNewContext script, ctx,
    filename: plugin.path
    lineOffset: plugin.line
    timeout: 120 * 1000

  return ctx.plugin