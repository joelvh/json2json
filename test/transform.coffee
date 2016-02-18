require('chai').should()
json2json = require '../'

json =
  breakfastMenuMap:
    name: 'Belgian Waffles',
    price: '$5.95'
  breakfastMenuArray: [
    { name: 'Belgian Waffles', price: '$5.95' }
  ]

describe 'ObjectTemplate', ->

  describe '#transform()', ->

    it 'should wrap the property in an array if `ensureArray` is `true`', ->
      new json2json.ObjectTemplate { path: 'breakfastMenuMap', ensureArray: true, all: true }
        .transform json
        .should.deep.equal [ { name: 'Belgian Waffles', price: '$5.95' } ]

    it 'should not modify the property if it is already an array even if `ensureArray` is `true`', ->
      new json2json.ObjectTemplate { path: 'breakfastMenuArray', ensureArray: true, all: true }
        .transform json
        .should.deep.equal [ { name: 'Belgian Waffles', price: '$5.95' } ]