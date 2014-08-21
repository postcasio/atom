path = require 'path'

async = require 'async'
fs = require 'fs-plus'
request = require 'request'
_ = require 'underscore-plus'

donna = require 'donna'
tello = require 'tello'

module.exports = (grunt) ->
  {rm} = require('./task-helpers')(grunt)

  opts = stdio: 'inherit'

  getClassesToInclude = ->
    modulesPath = path.resolve(__dirname, '..', '..', 'node_modules')
    classes = {}
    fs.traverseTreeSync modulesPath, (modulePath) ->
      return true unless path.basename(modulePath) is 'package.json'
      return true unless fs.isFileSync(modulePath)

      apiPath = path.join(path.dirname(modulePath), 'api.json')
      if fs.isFileSync(apiPath)
        _.extend(classes, grunt.file.readJSON(apiPath).classes)
      true
    classes

  grunt.registerTask 'build-docs', 'Builds the API docs in src', ->
    done = @async()
    docsOutputDir = grunt.config.get('docsOutputDir')

    metadata = donna.generateMetadata(['.'])
    telloJson = _.extend(tello.digest(metadata), getClassesToInclude())

    files = [{
      filePath: path.join(docsOutputDir, 'donna.json')
      contents: JSON.stringify(metadata, null, '  ')
    }, {
      filePath: path.join(docsOutputDir, 'tello.json')
      contents: JSON.stringify(telloJson, null, '  ')
    }]

    writeFile = ({filePath, contents}, callback) ->
      fs.writeFile filePath, contents, (error) ->
        callback(error)

    async.map files, writeFile, -> done()
