try {
  module.exports = require('./compiled');
} catch (err) {
  require('coffee-script/register');
  module.exports = require('./lib/json2json');
}
