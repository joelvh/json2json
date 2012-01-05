
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

    # Define a variable to hold your template object. 
    # When the JSON object is transformed, the root template will process the root of the 
    # JSON object. 
    tmpl = 
      # The "path" property (required) describes what property to transform in the JSON object. 
      # The '.' value specifies that the root of the JSON object should be transformed. 
      # The JSON object could be an object or an array. 
      path: '.'
      # The "aggregate" property (optional) allows you to combine array values into one value. 
      # (Think of it as the "reduce" part of a map/reduce.) 
      # Each property of the "aggregate" object specifies a function that handles each value in an array. 
      # You can manipulate the "existing" value (anything that has already been aggregated) 
      # or return a new value to use for the "items" property on your new JSON object. 
      # (You can specify as many )
      aggregate: 
      	items: (key, value, existing) -> if !isArray(value) then value else value[0]
      # The "as" property allows you to 
      as: 
        bins:  
          path: 'Items.SearchBinSets.SearchBinSet.Bin' 
          key: 'BinParameter.Value' 
          value: 'BinItemCount' 
          aggregate: (key, value, existing) -> Math.max(value, existing || 0) 
        items:  
          path: 'Items.Item' 
          all: true 
          as: 
            #ASIN: 'ASIN' 
            rank: 'SalesRank' 
            title: 'ItemAttributes.Title' 
            artist: 'ItemAttributes.Artist' 
            manufacturer: 'ItemAttributes.Manufacturer' 
            category: 'ItemAttributes.ProductGroup' 
            price: 'Offers.Offer.OfferListing.Price.FormattedPrice' 
            percent_saved: 'Offers.Offer.OfferListing.PercentageSaved' 
            availability: 'Offers.Offer.OfferListing.Availability' 
            price_new: 'OfferSummary.LowestNewPrice.FormattedPrice' 
            price_used: 'OfferSummary.LowestUsedPrice.FormattedPrice' 
            url: 'DetailPageURL' 
            similar: 
              path: 'SimilarProducts.SimilarProduct' 
              key: 'ASIN' 
              value: 'Title' 



    tmpl = 
      path: '.' 
      #all: true 
      aggregate:  
        total: (key, value, existing) -> if !sysmo.isArray(value) then value else value.sort().reverse()[0] 
        pages: (key, value, existing) -> if !sysmo.isArray(value) then value else value.sort().reverse()[0] 
      as: 
        bins:  
          path: 'Items.SearchBinSets.SearchBinSet.Bin' 
          key: 'BinParameter.Value' 
          value: 'BinItemCount' 
          aggregate: (key, value, existing) -> Math.max(value, existing || 0) 
        items:  
          path: 'Items.Item' 
          all: true 
          as: 
            #ASIN: 'ASIN' 
            rank: 'SalesRank' 
            title: 'ItemAttributes.Title' 
            artist: 'ItemAttributes.Artist' 
            manufacturer: 'ItemAttributes.Manufacturer' 
            category: 'ItemAttributes.ProductGroup' 
            price: 'Offers.Offer.OfferListing.Price.FormattedPrice' 
            percent_saved: 'Offers.Offer.OfferListing.PercentageSaved' 
            availability: 'Offers.Offer.OfferListing.Availability' 
            price_new: 'OfferSummary.LowestNewPrice.FormattedPrice' 
            price_used: 'OfferSummary.LowestUsedPrice.FormattedPrice' 
            url: 'DetailPageURL' 
            similar: 
              path: 'SimilarProducts.SimilarProduct' 
              key: 'ASIN' 
              value: 'Title' 
            images: 
              path: '.' 
              choose: ['SmallImage', 'MediumImage', 'LargeImage'] 
              format: (node, value, key) -> key: key.replace(/Image$/, '').toLowerCase() 
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
            links: 
              path: 'ItemLinks.ItemLink' 
              key: 'Description' 
              value: 'URL' 
    
    new ObjectTemplate(tmpl).transform data 

## License

Created by Joel Van Horn. Free to use however you please.