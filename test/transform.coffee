require('chai').should()
json2json = require '../'

json =
  breakfastMenuMap:
    name: 'Belgian Waffles',
    price: '$5.95'
  breakfastMenuArray: [
    { name: 'Belgian Waffles', price: '$5.95' }
  ]
  sportsTeams: [
    { id: 'yankees', name: 'New York Yankees', players: [ 'Alex', 'Starlin' ] }
    { id: 'cubs', name: 'Chicago Cubs', players: 'Jason' }
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

    it 'should wrap the map values in array when `key` and `value` are set and `ensureArray` is `true`', ->
      new json2json.ObjectTemplate { path: 'sportsTeams', key: 'id', value: 'players', ensureArray: true }
        .transform json
        .cubs.should.deep.equal [ 'Jason' ]