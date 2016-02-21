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
  user:
    name: 'Bob',
    title: '',
    age: undefined,
    email: null

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

    it 'does not include properties with a `null` or `undefined` value by default', ->
      new json2json.ObjectTemplate { path: 'user', all: true }
        .transform json
        .should.include.keys [ 'name', 'title' ]
        .should.not.include.keys [ 'age', 'email' ]

    it 'includes properties with a `null` or `undefined` value if `ignoreEmpty` is `false`', ->
      new json2json.ObjectTemplate { path: 'user', all: true, ignoreEmpty: false }
        .transform json
      .should.include.keys [ 'age', 'email' ]