module.exports =
  config:
    command:
      type: 'string'
      default: 'clang'
    includePaths:
      type: 'array'
      default: ['.']
    suppressWarnings:
      type: 'boolean'
      default: false
    defaultCFlags:
      type: 'string'
      default: '-Wall'
    defaultCppFlags:
      type: 'string'
      default: '-Wall -std=c++11'
    defaultObjCFlags:
      type: 'string'
      default: ' '
    defaultObjCppFlags:
      type: 'string'
      default: ' '
    errorLimit:
      type: 'integer'
      default: 0
    verboseDebug:
      type: 'boolean'
      default: false
    liveLinting:
      type: 'boolean'
      default: false

  activate: ->
    console.log 'activate linter-clang-plus' if atom.inDevMode()
