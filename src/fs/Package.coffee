{concat} = require '../utils'
isObject = require 'is-object'
crawl = require './crawl'
cush = require 'cush'
path = require 'path'

nextId = 1
nextFileId = 1

class Package
  constructor: (root, data) ->
    @id = 'p' + nextId++
    @root = root
    @data = data
    @files = Object.create null
    @bundles = new Set
    @exclude = []
    @crawled = false

  crawl: ->
    if not @crawled
      @crawled = true
      crawl @root, @files,
        skip: concat @exclude, cush.config('exclude')

  file: (name) ->
    file = @files[name]
    if typeof file is 'string'
      file = @files[file]
    if file is true
      @files[name] = file =
        id: 'f' + nextFileId++
        name: name
        ext: path.extname name
        content: null
        time: null
        map: null

    else if !file
      return null
    return file

  require: (name) ->
    name = path.join 'node_modules', name
    pack = @files[name]
    if isObject pack
      return pack
    if pack = tryPackage path.join @root, name
      @files[name] = pack
      return pack
    return null

module.exports = Package

#
# Internal
#

# TODO: watch the package.json of 'bad packages'
tryPackage = (root) ->
  try cush.package root
  catch err
    cush.emit 'warning',
      code: 'BAD_PACKAGE'
      message: err.message
      package: root
    return