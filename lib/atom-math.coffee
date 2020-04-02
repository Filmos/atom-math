{CompositeDisposable} = require 'atom'

module.exports = AtomMath =

  historyManager: null
  coreCommander:  null
  parser:         null
  mathUtils:      null

  activate: (state) ->
    
    HistoryManager = require './history-manager'
    @historyManager = HistoryManager.getManager()

    CoreCommander  = require './core-commander'
    @coreCommander = new CoreCommander()

    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-math:evaluate': (event) =>
        @evaluate event

    @subscriptions.add atom.commands.add 'atom-text-editor',
      'atom-math:getPreviousHistoryCommand': (event) =>
        @getPreviousHistoryCommand()

    @subscriptions.add atom.commands.add 'atom-text-editor',
      'atom-math:getNextHistoryCommand': (event) =>
        @getNextHistoryCommand()

  initialize: (serializeState) ->

  getPreviousHistoryCommand: ->
    @printOnBuffer @historyManager.getPreviousHistoryCommand()

  getNextHistoryCommand: ->
    @printOnBuffer @historyManager.getNextHistoryCommand()

  printOnBuffer: (toPrint) ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor
      return

    if toPrint?
      editor.moveToBeginningOfLine()
      editor.selectToEndOfLine()
      editor.insertText toPrint

  evaluate: ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor
      return
      
    selections = editor.getSelections()
    results = []
    for cursor in selections
      cursor.clear()
      currentRow = cursor.getBufferRange().end.row
      if editor.lineTextForBufferRow(currentRow) is 0
        results.push ''
        continue
      
      toEvaluate = editor.lineTextForBufferRow(currentRow).trim()
      @historyManager.addCommand toEvaluate
      
      if toEvaluate.startsWith('/') and @coreCommander.isCoreCommand toEvaluate
        result = @coreCommander.runCoreCommand toEvaluate
      else
        @mathUtils ?= require './math-utils'
        result = @mathUtils.evaluateExpression toEvaluate
      results.push result
      
    batchUndo = ->
      editor.moveToEndOfLine()
      editor.insertNewline()
      for i of selections
        if selections[i].getBufferRange().start.row is 0
          continue
        selections[i].insertText "> #{results[i]}"
      editor.insertNewline()
    editor.transact(batchUndo)

  deactivate: ->
    @subscriptions.dispose()

    @historyManager = null
    @coreCommander  = null
    @parser         = null
