Finally had a little time to start looking into ANW-700 and what we talked about last week. I went digging in the docs for the jquery tokenizer thing that ASpace uses, and realized this could all be handled straight in the linker.js Gonna pop a gist up to show you what I've done. It's ugly as all get out, but I think it's the proper route to take this.

https://gist.github.com/lorawoodford/69cf61d3ea0bae72dc1d6f9297d935bd

The meat of the changes are in lines 240 and lines 291-297.

240 works for the typeahead pre-save and seems pretty straightforward (that four_part_id is available as a separately indexed field in SOLR so you can just call it there with the typeahead search

291-297 is ugly and proof-of-concept and should probably be pulled out as a separate function with some better logic there, but show's how you can pull the fields out that are needed to concat and construct the equivalent of the four_part_id from the id_0 through id_3 fields available in the json once the record has been saved.

This is for after the object has been saved. Unfortunately, it's slightly less straightforward since that is driven by the json for the object (which doesn't have four_part_id) instead of the solr index which is used in the typeahead pre-save
