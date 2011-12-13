
sysmo = require 'sysmo'

class ObjectTemplate
  constructor: (config, parent) ->
    @config = @processConfig config
    @parent = parent
  
  transform: (data) =>
    @data = data;
    node = @nodeToProcess data
    
    return data if !node?
    
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
    switch sysmo.type node
      when 'Array' then @processArray node
      when 'Object' then @processMap node
      else node
  
  # assume each array element is a map
  processArray: (node) =>
    # convert array to hash
    if @config.key
      context = {}
      
      if @config.deep
        binder = (element, index) =>
          key = @chooseKey element
          value = @processProperties element
          context[key] = value
      else
        binder = (element, index) =>
          key = @chooseKey element
          value = @chooseValue(element, {})
          formatted = @formatNodes node, value, key
          context[formatted.key] = formatted.value
    else
      context = []
      binder = (element, index) =>
        value = @chooseValue(element, {})
        formatted = @formatNodes node, value, index
        context.push formatted.value
    
    for element, index in node
      binder element, index if @config.deep || @chooseNodes node, element, index
    context
    
  processMap: (node) =>
    if @config.nest
      context = {}
      # loop through properties to pick up any key/values that should be nested
      for key, value of node
        if @chooseNodes node, value, key
          nested_value = @chooseValue @getNode(node, key), {}
          formatted = @nestNodes node, nested_value, key
          context[formatted.key] = formatted.value
    else
      value = @chooseValue node, {}
      context = value
    context
    
  nestNodes: (node, value, key) =>
    return { key: key, value: value } if !sysmo.isFunction @config.nest
    nested = @config.nest node, value, key
    nested.key = key if 'key' not of nested
    nested.value = value if 'value' not of nested
    nested
  
  formatNodes: (node, value, key) =>
    # set default formatter or proxy existing
    return { key: key, value: value } if !@config.format
    
    formatted = @config.format node, value, key
    formatted.key = key if 'key' not of formatted
    formatted.value = value if 'value' not of formatted
    formatted
    
  chooseNodes: (node, value, key) =>
    # convert array to chooser function that compares key names
    if !@config.choose
      return true if @config.all or (@config.key and @config.value)
      @config.choose = []
      for key, value of @config.as
        @config.choose.push value.split('.')[0] if sysmo.isString(value)
    # create callback for arry
    if sysmo.isArray @config.choose
      for element in @config.choose
        return true if sysmo.isNumber(key) or element is key
      return false
    # if not a function yet, treat as boolean value
    if !sysmo.isFunction @config.choose
      # if config.key and config.value exist, most likely want to map all
      choosen = @config.all or (@config.key and @config.value)
      !!@config.choose #boolean
    else
      !!@config.choose node, value, key
      
  chooseKey: (node) =>
    # if @config.value exists, use that property of the array element as the value
    switch sysmo.type @config.key
      # custom function chooses value based on element
      when 'Function' then @config.value node
      # path specifies value from element
      #when 'String' then @getNode node, @config.key
      else @getNode node, @config.key
    
  chooseValue: (node, context) =>
    # if @config.value exists, use that property of the array element as the value
    switch sysmo.type @config.value
      # custom function chooses value based on element
      when 'Function' then @config.value node
      # path specifies value from element
      when 'String' then @getNode node, @config.value
      # normal mapping ensues
      else 
        # if @config.include exists, it's assumed to be an array
        if sysmo.isArray @config.include
          (context = @processTemplate node, context, @templates(name, as)) for name, as of @config.include
        # process currently defined template
        if @config.as
          context = @processTemplate node, context, @config.as
        context
  
  processTemplate: (node, context, template = {}) =>
    defaultFilter = (node, value) -> value
    # loop through properties in template
    for key, value of template
      # process mapping instructions
      switch sysmo.type value
        # string should be the path to a property on the current node
        when 'String' then filter = (node, path) => @getNode(node, path) or null
        # array gets multiple property values
        when 'Array' then filter = (node, paths) => @getNode(node, path) for path in paths
        # function is a custom filter for the node
        when 'Function' then filter = true
        # object should be { path: 'path.to.node', defaultValue: ... }
        # when 'Object' then filter = (node, value) -> @getNode(node, value.path) or value.defaultValue
        when 'Object' then filter = (node, config) => new @constructor(config, @).transform node
        else filter = defaultFilter
      
      # if the template specifies a function, pass node and key, otherwise it's an internal filter
      value = if filter is true then filter node, key else filter node, value
      # format key and value
      formatted = @formatNodes node, value, key
      context[formatted.key] = formatted.value
    
    if !@config.nest
      # loop through properties iode to pick up any key/values that should be choose
      for key, value of node
        # skip if node property already used, the property was specified by the template, or it should not be choose
        if @paths(node).indexOf(key) is -1 and key not in context and @chooseNodes node, value, key
          formatted = @formatNodes node, value, key
          context[formatted.key] = formatted.value
      
    context
  
  nodeToProcess: (node) =>
    @getNode node, @config.path
  
  getNode: (node, path) =>
    return node if path is '.'
    @paths node, path
    sysmo.getDeepValue node, path
    
  # track the first property in a path for each node through object tree
  paths: (node, path) =>
    path = path.split('.')[0] if path
    
    if !@pathCache
      @pathNodes = if @parent then @parent.pathNodes else (@pathNodes = [])
      @pathCache = if @parent then @parent.pathCache else (@pathCache = [])
    
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