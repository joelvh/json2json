
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
    @directMap = !!(@arrayToMap and config.value)
    @nestTemplate = !!config.nested
    @formattable = sysmo.isFunction config.format
    @includeAll = !!config.all
    
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
    # choose() implies filtering
    return true if !@config.choose and @includeAll # and !@nestTemplate

    # convert array to chooser function that compares key names
    if !@config.choose and !@paths
      @paths = []
      for key, value of @config.as when sysmo.isString(value)
        @paths.push value.split('.')[0]
    # create callback for arry
    if sysmo.isArray @config.choose
      paths = @paths or []
      paths = paths.concat @config.choose
      return true for path in paths when path.split('.')[0] is key
      return false
    # if not a function yet, treat as boolean value
    if !sysmo.isFunction @config.choose
      # if config.key and config.value exist, most likely want to map all
      !!(@includeAll or @directMap) #boolean
    else
      !!@config.choose.call @, node, value, key
  
  # returns a b
  aggregate: (context, key, value, existing) =>
    if sysmo.isFunction(@config.aggregate)
      !! context[key] = @config.aggregate(key, value, existing)
    else if sysmo.isFunction(@config.aggregate?[key])
      !! context[key] = @config.aggregate[key](key, value, existing)
    else false
  
  applyFormatting: (node, value, key) =>
    pair = @config.format(node, value, key) if @formattable
    @ensureKeyValue key, value, pair
  
  ensureKeyValue: (key, value, pair = {}) ->
    pair.key = key if 'key' not of pair
    pair.value = value if 'value' not of pair
    pair
  
# register module
module.exports = TemplateConfig