'use strict'

###*
 # @ngdoc service
 # @name swarmApp.util
 # @description
 # # util
 # Service in the swarmApp.
###
angular.module('swarmApp').service 'util', class Util
  sum: (ns) -> _.reduce ns, ((a,b) -> a+b), 0
  assert: (val, message...) ->
    if not val
      console.error "Assertion error", message...
      throw new Error message
    return val
  walk: (obj, fn, path="", rets=[]) ->
    ret = fn obj, path
    if ret?
      rets.push ret
    if _.isArray obj
      for elem, index in obj
        @walk elem, fn, "#{path}[#{index}]", rets
    else if _.isObject obj
      for key, prop of obj
        @walk prop, fn, "#{path}.#{key}", rets
    return rets