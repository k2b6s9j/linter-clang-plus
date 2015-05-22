linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
path = require 'path'

class LinterClang extends Linter
  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: ['source.cpp', 'source.c', 'source.objcpp', 'source.objc']

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
  errorStream: 'stderr'
  linterName: 'clang'

  constructor: (@editor) ->
    @language = 'c++' if @editor.getGrammar().name == 'C++'
    @language = 'objective-c++' if @editor.getGrammar().name == 'Objective-C++'
    @language = 'c' if @editor.getGrammar().name == 'C'
    @language = 'objective-c' if @editor.getGrammar().name == 'Objective-C'

    @listen = []

    @listen << atom.config.observe 'linter-clang-plus.command', (value) =>
      @cmd = value
    @listen << atom.config.observe 'linter-clang-plus.includePaths', (value) =>
      @includePaths = value
    @listen << atom.config.observe 'linter-clang-plus.suppressWarnings',
      (value) =>
        @suppressWarnings = value
    @listen << atom.config.observe 'linter-clang-plus.defaultCFlags',
      (value) =>
        @defaultCFlags = value
    @listen << atom.config.observe 'linter-clang-plus.defaultCppFlags',
      (value) =>
        @defaultCppFlags = value
    @listen << atom.config.observe 'linter-clang-plus.defaultObjCFlags',
      (value) =>
        @defaultObjCFlags = value
    @listen << atom.config.observe 'linter-clang-plus.defaultObjCppFlags',
      (value) =>
        @defaultObjCppFlags = value
    @listen << atom.config.observe 'linter-clang-plus.errorLimit', (value) =>
      @errorLimit = value
    @listen << atom.config.observe 'linter-clang-plus.verboseDebug', (value) =>
      @verboseDebug = value
    @listen << atom.config.observe 'linter-clang-plus.liveLinting', (value) =>
      @liveLinting = value
    @listen << atom.config.observe 'linter-clang-plus.fileDetection', (value) =>
      @fileDetection = value

  lintFile: (filePath, callback) ->
    @cmd = "#{@cmd} -fsyntax-only"
    @cmd = "#{@cmd} -fno-caret-diagnostics"
    @cmd = "#{@cmd} -fno-diagnostics-fixit-info"
    @cmd = "#{@cmd} -fdiagnostics-print-source-range-info"
    @cmd = "#{@cmd} -fexceptions"
    @cmd = "#{@cmd} -x#{@language}"
    defaultFlags = switch @editor.getGrammar().name
      when 'C++' then @defaultCppFlags
      when 'Objective-C++' then @defaultObjCppFlags
      when 'C' then atom.config.get @defaultCFlags
      when 'Objective-C' then atom.config.get @defaultObjCFlags
    @cmd = "#{@cmd} -ferror-limit=#{@errorLimit}"
    @cmd = "#{@cmd} -w" if @suppressWarnings
    if @liveLinting
      file = (path.basename do @editor.getPath)
    else
      file = filePath
    for include in @includePaths
      @cmd = "#{@cmd} -I#{include}"
    # add file to regex to filter output to this file,
    # need to change filename a bit to fit into regex
    @regex = filePath.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&") +
      ':(?<line>\\d+):(?<col>\\d+):(\{(?<lineStart>\\d+):(?<colStart>\\d+)\\-(?<lineEnd>\\d+):(?<colEnd>\\d+)\}.*:)? ((?<error>(?:fatal )?error)|(?<warning>warning)): (?<message>.*)'
    if @liveLinting
      super(filePath, callback)
    else
      super(file, callback)
    console.log "linter-clang: command = #{@cmd}" if atom.inDevMode()

  destroy: ->
    for dispose in @listen
      dispose.dispose()

module.exports = LinterClang
