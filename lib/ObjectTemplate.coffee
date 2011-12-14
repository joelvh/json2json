
sysmo = require 'sysmo'

class ObjectTemplate
  constructor: (config, parent) ->
    @config = @processConfig config
    @parent = parent
  
  transform: (data) =>
    @data = data;
    node = @nodeToProcess data
    
    return null if !node?
    
    @processProperties node
  
  processConfig: (config) =>
    # if there is no node path, set to current node
    config.path or= '.'
    # ensure 'as' template exists
    config.as or= {}
    # convert property name to array
    config.choose = [config.choose] if sysmo.isString config.choose
    # include multiple templates to apply before this one
    config.include = [config.include] if sysmo.isString config.include
    config
    
  processProperties: (node) =>
    
    node = @convertToArray node
    
    switch sysmo.type node
      when 'Array' then @processArray node
      when 'Object' then @processMap node
      else null #node
  
  # assume each array element is a map
  processArray: (node) =>
    # convert array to hash
    return @convertToMap(node) if @config.key
    
    context = []
    for element, index in node when @isProcessable node, element, index
      value = @chooseValue(element, {})
      formatted = @applyFormatting node, value, index
      context.push formatted.value if formatted.value?
    
    context
  
  # flatten an array of arrays, or if one element, convert to array
  convertToArray: (node) =>
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
    
    for element, index in node when @isProcessable node, element, index
      key = @chooseKey element
      value = @chooseValue(element, {})
      formatted = @applyFormatting node, value, key
      @aggregateValue context, formatted.key, formatted.value
        
    context
  
  aggregateValue: (context, key, value) =>
    return context if !value?
    
    existing = context[key]
    
    # should probalby use .hasOwnProperty, but values shouldn't be null
    if !existing?
      context[key] = value
    else if sysmo.isFunction(@config.aggregate)
      context[key] = @config.aggregate(key, value, existing)
    else if !sysmo.isArray(existing)
      context[key] = [existing, value]
    else
      context[key].push value
      
    context
  
  processMap: (node) =>
    
    return @chooseValue(node, {}) if !@config.nest
    
    context = {}
    # loop through properties to pick up any key/values that should be nested
    for key, value of node when @isProcessable node, value, key
      nested_value = @chooseValue @getNode(node, key), {}
      formatted = @nestNodes node, nested_value, key
      @aggregateValue context, formatted.key, formatted.value
    context
    
  nestNodes: (node, value, key) =>
    return { key: key, value: value } if !sysmo.isFunction @config.nest
    nested = @config.nest node, value, key
    nested.key = key if 'key' not of nested
    nested.value = value if 'value' not of nested
    nested
  
  applyFormatting: (node, value, key) =>
    # set default formatter or proxy existing
    return { key: key, value: value } if !@config.format
    
    formatted = @config.format node, value, key
    formatted.key = key if 'key' not of formatted
    formatted.value = value if 'value' not of formatted
    formatted
    
  isProcessable: (node, value, key) =>
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
      
  chooseKey: (node) =>
    # if @config.value exists, use that property of the array element as the value
    switch sysmo.type @config.key
      # custom function chooses value based on element
      when 'Function' then @config.key.call @, node
      # path specifies value from element
      #when 'String' then @getNode node, @config.key
      else @getNode node, @config.key
    
  chooseValue: (node, context) =>
    # if @config.value exists, use that property of the array element as the value
    switch sysmo.type @config.value
      # custom function chooses value based on element
      when 'Function' then @config.value.call @, node
      # path specifies value from element
      when 'String' then @getNode node, @config.value
      # normal mapping ensues
      else 
        # if @config.include exists, it's assumed to be an array
        #if sysmo.isArray @config.include
        #  (context = @processTemplate node, context, @templates(name, as)) for name, as of @config.include
        # process currently defined template
        #if @config.as
        context = @processTemplate node, context, @config.as
        context
  
  processTemplate: (node, context, template = {}) =>
    defaultFilter = (node, value) -> value
    # loop through properties in template
    for key, value of template
      # process mapping instructions
      switch sysmo.type value
        # string should be the path to a property on the current node
        when 'String' then filter = (node, path) => result = @getNode(node, path) or null
        # array gets multiple property values
        when 'Array' then filter = (node, paths) => @getNode(node, path) for path in paths
        # function is a custom filter for the node
        when 'Function' then filter = true
        # object should be { path: 'path.to.node', defaultValue: ... }
        # when 'Object' then filter = (node, value) -> @getNode(node, value.path) or value.defaultValue
        when 'Object' then filter = (node, config) => new @constructor(config, @).transform node
        else filter = defaultFilter
      
      # if the template specifies a function, pass node and key, otherwise it's an internal filter
      value = if filter is true then value.call(@, node, key) else filter(node, value)
      # format key and value
      formatted = @applyFormatting node, value, key
      @aggregateValue context, formatted.key, formatted.value
      
    if !@config.nest
      # loop through properties iode to pick up any key/values that should be choose
      # skip if node property already used, the property was specified by the template, or it should not be choose
      for key, value of node when @paths(node).indexOf(key) is -1 and key not in context and @isProcessable node, value, key
        formatted = @applyFormatting node, value, key
        @aggregateValue context, formatted.key, formatted.value
      
    context
  
  nodeToProcess: (node) =>
    @getNode node, @config.path
  
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