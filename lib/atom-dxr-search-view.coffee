fs = require 'fs'
Highlights = require 'highlights'
path = require 'path'
{$, $$, View, TextEditorView, ScrollView} = require 'atom-space-pen-views'


highlighter = new Highlights()


highlightLine = (line, filePath) ->
  line = line.replace('<b>', '').replace('</b>', '')
  line = $('<div />').html(line).text()
  return highlighter.highlightSync
    fileContents: line
    filePath: filePath


class ResultListView extends ScrollView
  @content: ->
    # settings-view class is for good alert coloring, maybe not a great idea.
    @div class: 'result-list-view', =>
      @ul class: 'list-group', outlet: 'resultList'
      @div class: 'show-more hidden', outlet: 'showMore', =>
        @button class: 'btn', 'Show more results'
      @div class: 'settings-view', =>
        @div class: 'hidden', outlet: 'message'

  showMessage: (message, type) ->
    @message.text message
    @message.attr 'class', "alert alert-#{type} icon icon-search"

  showShowMore: ->
    @showMore.removeClass 'hidden'

  hideShowMore: ->
    @showMore.addClass 'hidden'

  emptyResults: ->
    @resultList.empty()

  renderResults: (results) ->
    @message.addClass 'hidden'

    results?.forEach (result) =>
      @resultList.append $$ ->
        @li {class: 'list-item result', 'data-path': result.path}, =>
          @div class: 'path', =>
            @span {class: 'icon-file-text', 'data-name': result.path}
            @text result.path
          @ul class: 'result-lines', =>
            (@li 'data-line': line.line_number, =>
              @div class: 'result-line-number', line.line_number
              @div class: 'result-line', =>
                @raw highlightLine(line.line, result.path)
            ) for line in result.lines


module.exports = class DXRSearchView extends View
  dxrSearchView: null
  offset: 0
  lastQuery: null

  @config:
    server:
      type: 'string'
      default: 'https://dxr.mozilla.org'
    tree:
      type: 'string'
      default: 'mozilla-central'
    resultsPerPage:
      type: 'integer'
      default: 10

  @activate: (state) ->
    @dxrSearchView = new DXRSearchView state.dxrSearchViewState

  @deactivate: ->
    @dxrSearchView.detach()

  @content: (params) ->
    @div class: 'dxr-search', =>
      @p outlet:'message', class:'message icon icon-search',
        'Enter your DXR search query and hit Return to search.'
      @subview 'query', new TextEditorView mini: true
      @subview 'resultListView', new ResultListView()

  initialize: (serializeState) ->
    atom.commands.add 'atom-workspace', 'atom-dxr-search:toggle', => @toggle()
    atom.commands.add @element,
      'core:confirm': => @search(@query.getText())
      'core:cancel': => @detach()

    @resultListView.on 'click', '.result-lines li', (ev) => @clickLine(ev)
    @resultListView.on 'click', '.path', (ev) => @clickPath(ev)
    @resultListView.on 'click', '.show-more button', (ev) => @clickShowMore(ev)

  toggle: ->
    if @hasParent()
      @detach()
    else
      @attach()

  attach: ->
    @previouslyFocusedElement = $(':focus')
    @panel = atom.workspace.addModalPanel item: this
    @query.focus()

    @parent('.modal').css
      'max-height': '100%'
      display: 'flex'
      'flex-direction': 'column'

  detach: ->
    super
    @panel?.destroy()
    @resultListView.emptyResults()
    @resultListView.hideShowMore()
    @query.setText ''
    @restoreFocus()

  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.views.getView(atom.workspace).focus()

  search: (query, append=false) ->
    @resultListView.emptyResults() unless append
    @resultListView.hideShowMore()

    @lastQuery = query
    @resultListView.showMessage "Searching DXR with query \"#{query}\"...", 'info'
    limit = atom.config.get 'atom-dxr-search.resultsPerPage'
    server = atom.config.get 'atom-dxr-search.server'
    tree = atom.config.get 'atom-dxr-search.tree'
    data =
      q: query
      redirect: false
      format: 'json'
      case: false
      limit: limit
      offset: @offset

    $.ajax
      url: "#{server}/#{tree}/search",
      data: data,
      success: (response) =>
        @resultListView.renderResults response.results
        @resultListView.showShowMore() unless response.results.length < 1
        if append
          @offset += limit
        else
          @offset = limit
      error: (jqXHR, textStatus) =>
        @resultListView.showMessage "Error searching DXR: #{textStatus}", 'error'

  clickShowMore: (ev) ->
    @search(@lastQuery, true) unless not @lastQuery?

  clickLine: (ev) ->
    listItem = $(ev.target).parents '.result-lines > li'
    line = listItem.data 'line'
    filePath = listItem.parents('.result').data 'path'
    @openPath filePath, line

  clickPath: (ev) ->
    filePath = $(ev.target).parents('.result').data 'path'
    @openPath filePath

  openPath: (filePath, line) ->
    for basePath in atom.project.getPaths()
      possiblePath = path.join basePath, filePath
      if fs.existsSync possiblePath
        line = if line isnt undefined then line - 1  else 0
        atom.workspace.open possiblePath, initialLine: line
        @detach()
        return

    atom.notifications.addWarning 'Could not find local file matching this result.'
