
sysmo = require 'sysmo'

class TemplateConfig
  constructor: (config) ->
    # if there is no node path, set to current node
    config.path or= '.'
    # ensure 'as' template exists
    config.as or= {}
    # convert property name to array
    config.choose = [config.choose] if sysmo.isString config.choose
    # include multiple templates to apply before this one
    config.include = [config.include] if sysmo.isString config.include
    
    # create settings
    @arrayToMap = !!config.key
    @nestable = sysmo.isFunction config.nest
    @formattable = sysmo.isFunction config.format
    #TODO: is this used?
    @union = config.union
    
    @config = config
  
  getPath: =>
    @config.path
  
  getKey: (node) =>
    switch sysmo.type @config.key
      when 'Function'   then  name: 'value',    value: @config.key node
      else                    name: 'path',     value: @config.key
    
  getValue: (node, context) =>
    switch sysmo.type @config.value
      when 'Function'   then  name: 'value',    value: @config.value node
      when 'String'     then  name: 'path',     value: @config.value
      else                    name: 'template', value: @config.as
  
  processable: (node, value, key) =>
    # handling an array is much simpler, if not a function, 
    return true if sysmo.isArray(node) and !sysmo.isFunction(@config.choose) #(@config.key and @config.value)
    
    # convert array to chooser function that compares key names
    if !@config.choose
      @config.choose = []
      for key, value of @config.as when sysmo.isString(value)
        @config.choose.push value.split('.')[0]
    # create callback for arry
    if sysmo.isArray @config.choose
      return true for element in @config.choose when sysmo.isNumber(key) or element is key
      return false
    # if not a function yet, treat as boolean value
    if !sysmo.isFunction @config.choose
      # if config.key and config.value exist, most likely want to map all
      @config.choosen = @config.all or (@config.key and @config.value)
      !!@config.choose #boolean
    else
      !!@config.choose.call @, node, value, key
  
  # returns a b
  aggregate: (context, key, value, existing) =>
    
    if sysmo.isFunction(@config.aggregate)
      !! context[key] = @config.aggregate(key, value, existing)
    else if @config.aggregate?[key]
      !! context[key] = @config.aggregate[key](key, value, existing)
    else false
  
  applyNesting: (node, value, key) =>
    pair = @config.nest(node, value, key) if @nestable
    @ensureKeyValue key, value, pair
  
  applyFormatting: (node, value, key) =>
    pair = @config.format(node, value, key) if @formattable
    @ensureKeyValue key, value, pair
  
  ensureKeyValue: (key, value, pair = {}) ->
    pair.key = key if 'key' not of pair
    pair.value = value if 'value' not of pair
    pair
  
# register module
module.exports = TemplateConfig