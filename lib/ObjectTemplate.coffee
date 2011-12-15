
sysmo = require 'sysmo'
TemplateConfig = require './TemplateConfig'

class ObjectTemplate
  constructor: (config, parent) ->
    @config = new TemplateConfig config
    @parent = parent
  
  transform: (data) =>
    @data = data;
    node = @nodeToProcess data
    
    return null if !node?
    
    @processProperties node
  
  processProperties: (node) =>
    
    node = @makeFlattenedArray node
    
    switch sysmo.type node
      when 'Array'  then @processArray node
      when 'Object' then @processMap node
      else null #node
  
  # assume each array element is a map
  processArray: (node) =>
    # convert array to hash
    return @convertToMap(node) if @config.arrayToMap
    
    context = []
    
    for element, index in node when @config.processable node, element, index
      value = @chooseValue(element, {})
      formatted = @config.applyFormatting node, value, index
      context.push formatted.value if formatted.value?
    
    context
  
  # flatten an array of arrays, or if one element, convert to array
  makeFlattenedArray: (node) =>
    # don't do anything if a union option isn't specified
    return node if !@config.union
    # convert to array
    node = [node] if !sysmo.isArray(node)
    
    flattened_array = []
    
    for element in node
      child_array = @getNode element, @config.union
      # if not an array, make into array before merging
      child_array = [child_array] if !sysmo.isArray(child_array)
      # add each child to the master array
      flattened_array.push(child) for child in child_array when child?
    
    flattened_array
    
  convertToMap: (node) =>
    context = {}
    
    for element, index in node when @config.processable node, element, index
      key = @chooseKey element
      value = @chooseValue(element, {})
      formatted = @config.applyFormatting node, value, key
      @aggregateValue context, formatted.key, formatted.value
        
    context
  
  aggregateValue: (context, key, value) =>
    return context if !value?
    
    existing = context[key]
    
    return context if @config.aggregate context, key, value, existing
    
    if !existing?
      context[key] = value
    else if !sysmo.isArray(existing)
      context[key] = [existing, value]
    else
      context[key].push value
      
    context
  
  processMap: (node) =>
    
    return @chooseValue(node, {}) if !@config.nestable
    
    context = {}
    # loop through properties to pick up any key/values that should be nested
    for key, value of node when @config.processable node, value, key
      nested_value = @chooseValue @getNode(node, key), {}
      formatted = @config.applyNesting node, nested_value, key
      @aggregateValue context, formatted.key, formatted.value
    context
    
  processTemplate: (node, context, template = {}) =>
    
    # loop through properties in template
    for key, value of template
      # process mapping instructions
      switch sysmo.type value
        # string should be the path to a property on the current node
        when 'String'   then  filter = (node, path)   => result = @getNode(node, path) or null
        # array gets multiple property values
        when 'Array'    then  filter = (node, paths)  => @getNode(node, path) for path in paths
        # function is a custom filter for the node
        when 'Function' then  filter = (node, value)  => value.call(@, node, key)
        when 'Object'   then  filter = (node, config) => new @constructor(config, @).transform node
        else                  filter = (node, value)  -> value
      
      value = filter(node, value)
      # format key and value
      formatted = @config.applyFormatting node, value, key
      @aggregateValue context, formatted.key, formatted.value
      
    if !@config.nestable
      # loop through properties iode to pick up any key/values that should be choose
      # skip if node property already used, the property was specified by the template, or it should not be choose
      for key, value of node when @paths(node).indexOf(key) is -1 and key not in context and @config.processable node, value, key
        formatted = @config.applyFormatting node, value, key
        @aggregateValue context, formatted.key, formatted.value
      
    context
  
  chooseKey: (node) =>
    result = @config.getKey node
    switch result.name
      when 'value'    then result.value
      when 'path'     then @getNode node, result.value
      else null
    
  chooseValue: (node, context) =>
    result = @config.getValue node
    switch result.name
      when 'value'    then result.value
      when 'path'     then @getNode node, result.value
      when 'template' then @processTemplate node, context, result.value
      else null
  
  nodeToProcess: (node) =>
    @getNode node, @config.getPath()
  
  getNode: (node, path) =>
    return node if path is '.'
    @paths node, path
    sysmo.getDeepValue node, path, true
    
  # track the first property in a path for each node through object tree
  paths: (node, path) =>
    path = path.split('.')[0] if path
    
    @pathNodes or= @parent and @parent.pathNodes or []
    @pathCache or= @parent and @parent.pathCache or []
    
    index = @pathNodes.indexOf node
    
    if !path
      return if index isnt -1 then @pathCache[index] else []
    
    if index is -1
      paths = []
      @pathNodes.push node
      @pathCache.push paths
    else
      paths = @pathCache[index]
    
    paths.push(path) if path and paths.indexOf(path) == -1
    paths
  
  templates: (name, config) =>
    if !@templateCache
      @templateCache = if @parent then @parent.templateCache else {}
    if name and !config
      @templateCache[name] or null
    else if name and config
      @templateCache[name] = @processConfig config
      @templateCache
    else
      @templateCache

# register module
module.exports = ObjectTemplate