
## About json2json

This is a little utility that will transform one JSON object structure to another structure defined by a template. 
json2json is ideal for consuming JSON from a web service and transforming it into the structure your application needs it in. 

json2json is written in CoffeeScript, which is easily translated into JavaScript. 
It's designed to run in a Node.js environment with the CoffeeScript package installed. 
You can require json2json just like any other package. 

## Template options

There are several template options for transforming JSON. 
The template describes what the resulting document structure will look like. 

### Basic template structure

A template specifies a set of rules that describe how to transform a property in a JSON object. 
A template itself is a javascript object. 
This example is written in CoffeeScript and has in-line comments to explain each property: 

The template object is stored as the "tmpl" variable. 
The template typically matches the root of the JSON object. 

    tmpl = 
    
The "path" property specifies what property on the JSON object to process. 
The '.' value specifies to use the root in this case. 
The JSON object can be an array as well. 

      path: '.' 
      
The "aggregate" property (optional) is used if you are processing an array. 
It lets you process values of an array and combine them into one value or effectively filter an array. 
The properties in the "aggregate" object are used as properties on your new JSON object. 
The "existing" parameter sent to each aggregate function specifies a value if one exists on your new JSON object. 

      aggregate:  
        total: (key, value, existing) -> if !sysmo.isArray(value) then value else value.sort().reverse()[0] 
        pages: (key, value, existing) -> if !sysmo.isArray(value) then value else value.sort().reverse()[0] 

The "as" property lets you specify all the properties you want on your new JSON object. 
This is where you define the mapping rules. 
It is effectively a list of nested templates. 

      as: 

The "bins" property is going to be created on your new JSON object. 
The object defined as the value of "bins" here is another set of rules that define what property 
on the original JSON object to transform. 

        bins:  

The "path" property is described above. 
Here the value specifies where within the original JSON object to find the value you want. 
It is possible to access properties of objects that are in an array. 
An array of all values will be returned and used as the value to transform. 

          path: 'Items.SearchBinSets.SearchBinSet.Bin' 

The "key" property lets you convert an array to a map. 
The value of the "key" property specifies the path to the value to use as the property on the new map. 
The value retrieved from the original JSON object will be converted to a string. 

          key: 'BinParameter.Value' 

The "value" property (optional) lets you specify the property in the original JSON object to use as the value in the new map. 

          value: 'BinItemCount' 

The "aggregate" property works the same as above, but instead of specifying a map of functions, 
a single function is used to aggregate the array values being processed on the original JSON object.

          aggregate: (key, value, existing) -> Math.max(value, existing || 0) 
        items:  
          path: 'Items.Item' 

The "all" property specifies that all properties on the matched object in the original JSON object for which 
no rule has been defined should automatically be copied to the new JSON object.

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

The "choose" property defines an array of properties on the original JSON object to transform and skip the rest. 

              choose: ['SmallImage', 'MediumImage', 'LargeImage'] 

The "format" property defines a function that processes each of the values retrieved from the original JSON object 
and returns an object with "key" and "value" properties. 
This allows you to format the key and value however you wish. 
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
              choose: (node, value, key) -> key isnt '@' 
              format: (node, value, key) -> key: key.replace(/Image$/, '').toLowerCase() 
              nested: true 
              as: 
                url: 'URL' 
                height: 'Height.#' 
                width: 'Width.#' 
    
    new ObjectTemplate(tmpl).transform data 

## License

Created by Joel Van Horn. Free to use however you please.