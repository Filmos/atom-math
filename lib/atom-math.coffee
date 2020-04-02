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
    
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-math:evaluateInline': (event) =>
        @evaluateInline event

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
  
  parseInput: (input) ->
    @historyManager.addCommand input
    
    if input.startsWith('/') and @coreCommander.isCoreCommand input
      result = @coreCommander.runCoreCommand input
    else
      @mathUtils ?= require './math-utils'
      result = @mathUtils.evaluateExpression input
    return result
  
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
      results.push @parseInput toEvaluate
      
    batchUndo = ->
      editor.moveToEndOfLine()
      editor.insertNewline()
      for i of selections
        if selections[i].getBufferRange().start.row is 0
          continue
        selections[i].insertText "> #{results[i]}"
      editor.insertNewline()
    editor.transact(batchUndo)
  
  evaluateInline: ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor
      return
      
    selections = editor.getSelections()
    results = []
    for cursor in selections
      currentRow = cursor.getBufferRange().end.row
      if editor.lineTextForBufferRow(currentRow) is 0
        results.push ''
        continue
      
      newline = false
      if cursor.isEmpty()
        newline = true
        cursor.expandOverLine()
      
      toEvaluate = cursor.getText().trim()
      toEvaluate = toEvaluate.replace(/\n|\r/g," ")
      # results.push toEvaluate
      result = @parseInput toEvaluate
      if newline
        result += "\n"
      results.push result
      
    batchUndo = ->
      for i of selections
        if selections[i].getBufferRange().start.row is 0
          continue
        if results[i] != undefined
          selections[i].insertText "#{results[i]}"
    editor.transact(batchUndo)
  

  deactivate: ->
    @subscriptions.dispose()

    @historyManager = null
    @coreCommander  = null
    @parser         = null
