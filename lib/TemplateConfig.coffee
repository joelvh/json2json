# handle CommonJS/Node.js or browser

sysmo = require?('sysmo') || window?.Sysmo

# class definition

class TemplateConfig
  constructor: (config) ->
    # if there is no node path, set to current node
    config.path     or= '.'
    # ensure 'as' template exists
    config.as       or= {}
    # convert property name to array
    config.choose   = [config.choose] if sysmo.isString config.choose
    # include multiple templates to apply before this one
    config.include  = [config.include] if sysmo.isString config.include
    
    # create settings
    @arrayToMap     = !!config.key
    # TODO: Need to implement converting a map to an array... 
    #       This property was created to show how to specify converting maps to arrays
    @mapToArray     = !@arrayToMap and config.key is false and !config.as
    @directMap      = !!(@arrayToMap and config.value)
    @nestTemplate   = !!config.nested
    @includeAll     = !!config.all
    @ensureArray    = !!config.ensureArray
    @ignoreEmpty    = config.ignoreEmpty != false

    @config         = config
  
  getPath: =>
    @config.path
  
  # used to get a key when converting an array to a map
  getKey: (node) =>
    switch sysmo.type @config.key
      when 'Function'   then  name: 'value',    value: @config.key node
      else                    name: 'path',     value: @config.key
  
  # used to get a single value when converting an array to a map
  getValue: (node, context) =>
    switch sysmo.type @config.value
      when 'Function'   then  name: 'value',    value: @config.value node
      when 'String'     then  name: 'path',     value: @config.value
      else                    name: 'template', value: @config.as
  
  # indicates if the key/value pair should be included in transformation
  processable: (node, value, key) =>
    # no choose() implies all properties go, 
    # but there are other properties that may cause filtering
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
  
  # used to combine or reduce a value if one already exists in the context.
  # can be a map that aggregates specific properties
  aggregate: (context, key, value, existing) =>
    aggregator = @config.aggregate?[key] or @config.aggregate
    
    return false unless sysmo.isFunction(aggregator)
    
    context[key] = aggregator(key, value, existing)
    
    return true
  
  applyFormatting: (node, value, key) =>
    # if key is a number, assume this is an array element and skip
    if !sysmo.isNumber(key)
      formatter = @config.format?[key] or @config.format
      pair      = if sysmo.isFunction(formatter) then formatter(node, value, key) else {}
    else
      pair      = {}
    
    pair.key    = key if 'key' not of pair
    pair.value  = value if 'value' not of pair
    pair

# register module (CommonJS/Node.js) or handle browser

if module?
  module.exports = TemplateConfig
else
  window.json2json or= {}
  window.json2json.TemplateConfig = TemplateConfig