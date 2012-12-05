# load modules in CommonJS/Node.js environment, not needed in browser

if exports? && require?
  exports.ObjectTemplate = require './ObjectTemplate'
  exports.TemplateConfig = require './TemplateConfig'
else if window?
  window.json2json = {}