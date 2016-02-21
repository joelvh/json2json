# About json2json [![Build Status](https://travis-ci.org/joelvh/json2json.svg?branch=master)](https://travis-ci.org/joelvh/json2json)

Transforms one JSON object structure to another structure as defined by template rules. 
Ideal for transforming JSON retrieved from web services to be used the way you need it in your application. 

[json2json](https://github.com/joelvh/json2json) is written in [CoffeeScript](http://coffeescript.org) and designed to run in a [Node.js](http://nodejs.org) envirionment. 
It can be easily converted to JavaScript to be used in a browser as well.

# Tutorial

## Template rules

Template rules specify how the "original JSON" (raw data) is transformed to the "new JSON" format you need: 

A template specifies the **path** to the value on your original JSON you want to transform 
and assumes that value is either an object or an array. 
If it's an object, you can **choose** which properties you want to transform.
If it's an array, you can **aggregate** the values you want to transform. 

Sometimes you want to convert an array to a map (aka JSON object). 
To do this, you can specify what value on your original JSON to use as the **key**. 
If you want to make it a really simple map, 
you can specify what value on your original JSON to use as the **value**. 

Templates specify how the original JSON data will be represented **as** properties on the new JSON. 
(The only time the **as** rules are ignored is if the **value** rule exists 
when converting an array to a map.) 

## Describing the example template

(Look at the "[example](example)" folder to see this [template](example/template.coffee) and the JSON [before](example/original.json) and [after](example/transformed.json) transformation.) 

A template specifies a set of rules that describe how to transform a property in your original JSON. 
A template itself is a javascript object. 
This example is written in CoffeeScript and has comments to explain each property: 

The template object is stored as the "tmpl" variable. 
The template typically matches the root of the original JSON. 

    tmpl = 
    
The "path" property specifies what property on the JSON object to process. 
The '.' value specifies to use the root in this case. 
The original JSON can be an array as well. 

      path: '.' 
      
The "aggregate" property (optional) is used if you are processing an array. 
It lets you process values of an array and combine them into one value or effectively filter an array. 
The properties in the "aggregate" object are used as properties on your new JSON object. 
The "existing" parameter sent to each aggregate function specifies a value if one exists on your new JSON object. 

      aggregate:  
        total: (key, value, existing) -> if !sysmo.isArray(value) then value else value.sort().reverse()[0] 
        pages: (key, value, existing) -> if !sysmo.isArray(value) then value else value.sort().reverse()[0] 

The "as" property lets you specify all the properties you want on your new JSON object. 
(These are the only properties that will be created on the new JSON object.) 
This is where you define the mapping rules. 
It is effectively a list of nested templates. 

      as: 

The "bins" property is going to be created on your new JSON object. 
The template defined for "bins" here is another set of rules that specify what property 
on the original JSON object to transform. 

        bins:  

The "path" property was described previously. 
However, this time the path is relative to the value in the original JSON that was selected by the previous "path" (above). 
It is possible to access properties of objects that are in an array. 
A flattened array of all values will be returned and used as the value to transform. 

          path: 'Items.SearchBinSets.SearchBinSet.Bin' 

The "key" property indicates you want to convert an array to a map. 
The "key" property lets you specify the property in the original JSON object to use as the key in the new map. 
The value retrieved from the original JSON object will be converted to a string. 
(Alternatively, you can specify a function that is passed the original JSON value and returns a key to use.) 

          key: 'BinParameter.Value' 

The "value" property (optional) lets you specify the property in the original JSON object to use as the value in the new map. 
(Alternatively, you can specify a function that is passed the original JSON value and returns a value to use.) 

          value: 'BinItemCount' 

The "aggregate" property works the same as previously described, but instead of specifying a map of functions, 
a single function is used to aggregate the array values being processed on the original JSON object.

          aggregate: (key, value, existing) -> Math.max(value, existing || 0) 
        items:  
          path: 'Items.Item' 

The "all" property specifies that all properties on the matched object in the original JSON object for which 
no rule has been defined should automatically be copied to the new JSON object. 
(By default, only the properties specified in the "as" template are created on the new JSON.) 
The "all" option only works if "choose" is not defined (see below). 

          all: true 
          as: 
            title: 'ItemAttributes.Title' 
            price: 'Offers.Offer.OfferListing.Price.FormattedPrice' 
            similar: 
              path: 'SimilarProducts.SimilarProduct' 
              key: 'ASIN' 
              value: 'Title' 
            images: 
              path: '.'

Any properties on the matched object that are null or undefined will not be copied to the new JSON object.
To include these properties set "ignoreEmpty" to false.

          ignoreEmpty: false

The "choose" property defines an array of properties on the original JSON object to transform and skip the rest. 

              choose: ['SmallImage', 'MediumImage', 'LargeImage'] 

The "format" property defines a function that processes each of the values retrieved from the original JSON object 
and returns an object with "key" and "value" properties or an array which contains object(s) with "key" and "value" properties. If an array is returned, all entries in the array are added to the current context node in the new JSON. 
This allows you to format the key and value however you wish. 
(If a "key" or "value" property is not returned, the original value is used.) 
The "node" parameter to the format function is the object or array in the original JSON that is being transformed. 
(It is the object that contains the properties defined by the "choose" array.)

              format: (node, value, key) -> key: key.replace(/Image$/, '').toLowerCase() 

The "nested" property indicates that the value of each property specified by "choose" should be a new object. 
The properties defined in the "as" template below will be stored in the nested object instead of the object that the 
"choose" properties are created on.

              nested: true 
              as: 
                url: 'URL' 
                height: 'Height.#'  
                width: 'Width.#' 
            image_sets: 
              path: 'ImageSets.ImageSet' 
              key: '@.Category' 

The "choose" property can be a function that returns a boolean. 
In the previous "choose" example, an array of property names (e.g. map/hash "keys") were specified, 
which indicated what properties on the original JSON value to transform. 
To provide more flexibility, a function can be used to dynamically choose which properties to transform. 

              choose: (node, value, key) -> key isnt '@' 
              format: (node, value, key) -> key: key.replace(/Image$/, '').toLowerCase() 
              nested: true 
              as: 
                url: 'URL' 
                height: 'Height.#' 
                width: 'Width.#'

The "ensureArray" property indicates that the matched property should be wrapped in an array if it is not already an array.

              ensureArray: true

And finally, create an instance of the "ObjectTemplate" object, 
passing the template to the constructor. 
Then call the "transform" method, passing it the data you want to transform. 

    new ObjectTemplate(tmpl).transform data 

# Using json2json in your browser

You can use the json2json library in your browser by converting the CoffeeScript files to JavaScript first. 
You'll also need to include the [Sysmo.js](https://github.com/joelvh/Sysmo.js) dependency. 
Include the files in this order (the [json2json.coffee](lib/json2json.coffee) file is not necessary):

  1. [Sysmo.js](https://github.com/joelvh/Sysmo.js)
  2. TemplateConfig.js (converted from [TemplateConfig.coffee](lib/TemplateConfig.coffee))
  3. ObjectTemplate.js (converted from [ObjectTemplate.coffee](lib/ObjectTemplate.coffee))

From there on out, you can define your template (see [template example](example/template.coffee)) and use the classes in your JavaScript code.

# TODO

* Need to convert a map (object) to an array


## License

Created by Joel Van Horn. Free to use however you please.