# handle CommonJS/Node.js or browser

sysmo           = require?('sysmo') || window?.Sysmo
TemplateConfig  = require?('./TemplateConfig') || window?.json2json.TemplateConfig

# class definition

class ObjectTemplate
  constructor: (config, parent) ->
    @config = new TemplateConfig config
    @parent = parent
  
  transform: (data) =>
    node = @nodeToProcess data
    
    return null unless node?
    
    # process properties
    switch sysmo.type node
      when 'Array'  then @processArray node
      when 'Object' then @processMap node
      else null #node
  
  # assume each array element is a map
  processArray: (node) =>
    # convert array to hash if config.arrayToMap is true
    context = if @config.arrayToMap then {} else []
    
    for element, index in node #when @config.processable node, element, index
      # convert the index to a key if converting array to map 
      # @updateContext handles the context type automatically
      key = if @config.arrayToMap then @chooseKey(element) else index
      # don't call @processMap because it can lead to double nesting if @config.nestTemplate is true
      value = @createMapStructure(element)
      # because we don't call @processMap we have to manually ensure values are arrays
      if @config.arrayToMap and @config.ensureArray and !context[key]?
        value = [value]
      @updateContext context, element, value, key
    context
  
  processMap: (node) =>

    if @config.ensureArray then return @processArray [node]

    context = @createMapStructure node
    
    if @config.nestTemplate and (nested_key = @chooseKey(node))
      nested_context              = {}
      nested_context[nested_key]  = context;
      context                     = nested_context
    
    context
  
  createMapStructure: (node) =>
    
    context = {}
    
    return @chooseValue(node, context) unless @config.nestTemplate
    
    # loop through properties to pick up any key/values that should be nested
    for key, value of node when @config.processable node, value, key
      # call @getNode() to register the use of the property on that node
      nested  = @getNode(node, key)
      value   = @chooseValue nested
      @updateContext context, nested, value, key
    context
  
  chooseKey: (node) =>
    result = @config.getKey node
    
    switch result.name
      when 'value'    then result.value
      when 'path'     then @getNode node, result.value
      else null
    
  chooseValue: (node, context = {}) =>
    result = @config.getValue node
    
    switch result.name
      when 'value'    then result.value
      when 'path'     then @getNode node, result.value
      when 'template' then @processTemplate node, context, result.value
      else null
  
  processTemplate: (node, context, template = {}) =>
    
    # loop through properties in template
    for key, value of template
      # process mapping instructions
      switch sysmo.type value
        # string should be the path to a property on the current node
        when 'String'   then  filter = (node, path)   => @getNode(node, path)
        # array gets multiple property values
        when 'Array'    then  filter = (node, paths)  => @getNode(node, path) for path in paths
        # function is a custom filter for the node
        when 'Function' then  filter = (node, value)  => value.call(@, node, key)
        when 'Object'   then  filter = (node, config) => new @constructor(config, @).transform node
        else                  filter = (node, value)  -> value
      
      value = filter(node, value)
      @updateContext context, node, value, key
    
    @processRemaining context, node
    context
  
  processRemaining: (context, node) =>
    # loop through properties to pick up any key/values that should be chosen.
    # skip if node property already used, the property was specified by the template, or it should not be choose.
    for key, value of node when !@pathAccessed(node, key) and key not in context and @config.processable node, value, key
      @updateContext context, node, value, key
    context
    
  updateContext: (context, node, value, key) =>
    # format key and value
    formatted = @config.applyFormatting node, value, key
    if sysmo.isArray(formatted)
      @aggregateValue context, item.key, item.value for item in formatted
    else if formatted?
      @aggregateValue context, formatted.key, formatted.value
      
  aggregateValue: (context, key, value) =>
    return context unless value? or !@config.ignoreEmpty
    
    # if context is an array, just add the value
    if sysmo.isArray(context)
      context.push(value)
      return context
    
    existing = context[key]
    
    return context if @config.aggregate context, key, value, existing
    
    if !existing?
      context[key] = value
    else if !sysmo.isArray(existing)
      context[key] = [existing, value]
    else
      context[key].push value
      
    context
  
  nodeToProcess: (node) =>
    @getNode node, @config.getPath()
  
  getNode: (node, path) =>
    return null unless path
    return node if path is '.'
    @paths node, path
    sysmo.getDeepValue node, path, true
    
  pathAccessed: (node, path) =>
    key = path.split('.')[0]
    @paths(node).indexOf(key) isnt -1
    
  # track the first property in a path for each node through object tree
  paths: (node, path) =>
    path = path.split('.')[0] if path
    
    @pathNodes or= @parent and @parent.pathNodes or []
    @pathCache or= @parent and @parent.pathCache or []
    
    index = @pathNodes.indexOf node
    
    return (if index isnt -1 then @pathCache[index] else []) unless path
    
    if index is -1
      paths = []
      @pathNodes.push node
      @pathCache.push paths
    else
      paths = @pathCache[index]
    
    paths.push(path) if path and paths.indexOf(path) == -1
    paths
  
# register module (CommonJS/Node.js) or handle browser

if module?
  module.exports = ObjectTemplate
else
  window.json2json or= {}
  window.json2json.ObjectTemplate = ObjectTemplate
