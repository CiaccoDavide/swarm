'use strict'

###*
 # @ngdoc service
 # @name swarmApp.Kongregate
 # @description
 # # Kongregate
 # Service in the swarmApp.
 #
 # http://developers.kongregate.com/docs/api-overview/client-api
###
angular.module('swarmApp').factory 'isKongregate', ->
  return ->
    # use the non-# querystring to avoid losing it when the url changes. $location.search() won't work.
    # a simple string-contains is hacky, but good enough as long as we're not using the querystring for anything else.
    _.contains window.location.search, 'kongregate'
    # alternatives:
    # - #-querystring is overwritten on reload.
    # - url is hard to test, and flaky with proxies.
    # - separate deployment? functional, but ugly maintenance.
    # - when-framed-assume-kongregate? could work...
    # - hard-querystring (/?kongregate#/tab/meat) seems to work well! can't figure out how to get out of it in 30sec.

angular.module('swarmApp').factory 'Kongregate', (isKongregate, $log, $location, game, $rootScope, $interval) -> class Kongregate
  constructor: ->
  isKongregate: ->
    isKongregate()
  load: ->
    $log.debug 'loading kongregate script...'
    $.getScript 'https://cdn1.kongregate.com/javascripts/kongregate_api.js'
      .done (script, textStatus, xhr) =>
        $log.debug 'kongregate script loaded, now trying to load api', window.kongregateAPI
        # loadAPI() requires an actual kongregate frame, `?kongregate=1` in its own tab is insufficient. fails silently.
        window.kongregateAPI.loadAPI =>
          $log.debug 'kongregate api loaded'
          @kongregate = window.kongregateAPI.getAPI()
          @_onLoad()
      .fail (xhr, settings, exception) =>
        $log.error 'kongregate load failed', xhr, settings, exception

  onResize: -> #overridden on load
  _onLoad: ->
    $log.debug 'kongregate successfully loaded!', @kongregate
    @isLoaded = true
    @reportStats()

    ## configure resizing iframe
    #html = $(document.documentElement)
    #body = $(document.body)
    ## no blinking scrollbar on resize. https://stackoverflow.com/questions/2469529/how-to-disable-scrolling-the-document-body
    #document.body.style.overflow = 'hidden'
    #oldheight = null
    #olddate = new Date 0
    #@onResize = =>
    #  height = Math.max html.height(), body.height()
    #  if height != oldheight
    #    date = new Date()
    #    datediff = date.getTime() - olddate.getTime()
    #    # jumpy height changes while rendering, especially in IE!
    #    # throttle height decreases to 1 per second, to avoid some of the
    #    # jumpiness. height increases must be responsive though, so don't
    #    # throttle those. seems to be enough. (if this proves too jumpy, could
    #    # add a 100px buffer to size increases, but not necessary yet I think.)
    #    if height > oldheight or datediff >= 1000
    #      $log.debug "onresize: #{oldheight} to #{height} (#{if height > oldheight then 'up' else 'down'}), #{datediff}ms"
    #      oldheight = height
    #      olddate = date
    #      @kongregate.services.resizeGame 800, height
    ## resize whenever size changes.
    ##html.resize onResize
    ## NOPE. can't detect page height changes with standard events. header calls onResize every frame.
    #$log.debug 'setup onresize'

  reportStats: ->
    if not @isLoaded or not game.session.kongregate
      return
    # don't report more than once per minute
    now = new Date()
    if @lastReported and now.getTime() < @lastReported.getTime() + 60 * 1000
      return
    #if not @lastReported
    #  @kongregate.stats.submit 'Initialized', 1
    @lastReported = now
    @kongregate.stats.submit 'Hatcheries', @_count game.upgrade 'hatchery'
    @kongregate.stats.submit 'Expansions', @_count game.upgrade 'expansion'
    @kongregate.stats.submit 'GameComplete', @_count game.unit 'ascension'
    @kongregate.stats.submit 'Mutations Unlocked', @_count game.upgrade 'mutatehidden'
    @kongregate.stats.submit 'Achievement Points', game.achievementPoints()
    @_submitTimetrialMins 'Minutes to First Nexus', game.upgrade 'nexus1'
    @_submitTimetrialMins 'Minutes to Fifth Nexus', game.upgrade 'nexus5'
    @_submitTimetrialMins 'Minutes to First Ascension', game.unit 'ascension'

  _count: (u) ->
    return u.count().floor().toNumber()
  _timetrialMins: (u) ->
    if (millis = u.statistics()?.elapsedFirst)
      return Math.ceil millis / 1000 / 60
  _submitTimetrialMins: (name, u) ->
    time = @_timetrialMins u
    if time
      @kongregate.stats.submit name, time

angular.module('swarmApp').factory 'kongregate', ($log, Kongregate) ->

  ret = new Kongregate()
  $log.debug 'isKongregate:', ret.isKongregate()
  if ret.isKongregate()
    ret.load()
  return ret
