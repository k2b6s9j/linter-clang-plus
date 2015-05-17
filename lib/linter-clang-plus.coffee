{Range, Point, BufferedProcess, BufferedNodeProcess} = require 'atom'
linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
path = require 'path'
fs = require 'fs'

class LinterClang extends Linter
  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: ['source.cpp', 'source.c', 'source.objcpp', 'source.objc']

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
  @cmd: ''
  errorStream: 'stderr'
  linterName: 'clang'

  lintFile: (filePath, callback) ->
    # NOTE: there is a difference between projectPath and @cwd
    # projectPath is self explanatory, cwd is the path of the file being linted
    # these are NOT the same things!
    projectPath = atom.project.getPaths()[0]

    verbose = atom.config.get 'linter-clang.verboseDebug'

    # parse space separated string taking care of quotes
    splitSpaceString = (string) ->
      regex = /[^\s"]+|"([^"]*)"/gi
      stringSplit = []

      loop
        match = regex.exec string
        if match
          newItem = if match[1] then match[1] else match[0]
          if newItem.length > 0
              stringSplit.push(newItem)
        else
          break

      return stringSplit

    @cmd = [ atom.config.get 'linter-clang.clangCommand' ]

    {command, args} = @getCmdAndArgs(filePath)

    # Remove file path from args, it should be the last argument
    args.shift()

    args.push '-fsyntax-only'
    args.push '-fno-caret-diagnostics'
    args.push '-fno-diagnostics-fixit-info'
    args.push '-fdiagnostics-print-source-range-info'
    args.push '-fexceptions'
    args.push "-x#{@language}"

    defaultFlags = splitSpaceString switch @editor.getGrammar().name
        when 'C++'           then atom.config.get 'linter-clang.clangDefaultCppFlags'
        when 'Objective-C++' then atom.config.get 'linter-clang.clangDefaultObjCppFlags'
        when 'C'             then atom.config.get 'linter-clang.clangDefaultCFlags'
        when 'Objective-C'   then atom.config.get 'linter-clang.clangDefaultObjCFlags'

    args.push dflag for dflag in defaultFlags

    args.push "-ferror-limit=#{atom.config.get 'linter-clang.clangErrorLimit'}"
    args.push '-w' if atom.config.get 'linter-clang.clangSuppressWarnings'
    args.push '--verbose' if verbose

    expandMacros = (stringToExpand) =>
      stringToExpand = stringToExpand.replace '%d', @cwd
      stringToExpand = stringToExpand.replace '%p', projectPath
      stringToExpand = stringToExpand.replace '%%', '%'
      return stringToExpand

    includePaths = (base, ipathArray) =>
      for ipath in ipathArray
        if ipath
          pathExpanded = expandMacros(ipath)
          pathResolved = path.resolve(base, pathExpanded)
          console.log "linter-clang: including #{ipath}, which expanded to #{pathResolved}" if atom.inDevMode() and verbose
          args.push "-I#{pathResolved}"

    pathArray =
      splitSpaceString atom.config.get 'linter-clang.clangIncludePaths'

    includePaths @cwd, pathArray

    # Add file path as last argument
    args.push filePath

    # add file to regex to filter output to this file,
    # need to change filename a bit to fit into regex
    @regex = filePath.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&") +
      ':(?<line>\\d+):(?<col>\\d+):(\{(?<lineStart>\\d+):(?<colStart>\\d+)\\-(?<lineEnd>\\d+):(?<colEnd>\\d+)\}.*:)? ' +
      '((?<error>(?:fatal )?error)|(?<warning>warning)): (?<message>.*)'

    if atom.inDevMode()
      console.log 'linter-clang: is node executable: ' + @isNodeExecutable

    # use BufferedNodeProcess if the linter is node executable
    if @isNodeExecutable
      Process = BufferedNodeProcess
    else
      Process = BufferedProcess

    # options for BufferedProcess, same syntax with child_process.spawn
    options = {cwd: @cwd}

    stdout = (output) =>
      if atom.inDevMode()
        console.log 'clang: stdout', output
      if @errorStream == 'stdout'
        @processMessage(output, callback)

    stderr = (output) =>
      if atom.inDevMode()
        console.warn 'clang: stderr', output
      if @errorStream == 'stderr'
        @processMessage(output, callback)

    if atom.inDevMode()
      console.log "linter-clang: command = #{command}, args = #{args}, options = #{options}"

    new Process({command, args, options, stdout, stderr})

  constructor: (editor) ->
    @editor = editor

    if editor.getGrammar().name == 'C++'
      @language = 'c++'
      # @flag = '-std=c++11'
    if editor.getGrammar().name == 'Objective-C++'
      @language = 'objective-c++'
      # @flag = ''
    if editor.getGrammar().name == 'C'
      @language = 'c'
      # @flag = ''
    if editor.getGrammar().name == 'Objective-C'
      @language = 'objective-c'
      # @flag = ''

    super(editor)

  createMessage: (match) ->
    # message might be empty, we have to supply a value
    if match and match.type == 'parse' and not match.message
      message = 'error'

    super(match)

module.exports = LinterClang
