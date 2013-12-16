try {
  module.exports = require('./compiled');
} catch (err) {
  require('coffee-script');
  module.exports = require('./lib/json2json');
}
