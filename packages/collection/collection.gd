## Public API entry point for the Collection package.
##
## Barrel file that exports the Collection class.
## Use this to import the Collection class:
##
##   const Collection = preload("res://packages/collection/collection.gd")
##   var collection = Collection.Collection.new([1, 2, 3])
##
## Or import the class directly:
##   const Collection = preload("res://packages/collection/types/collection.gd")
##   var collection = Collection.new([1, 2, 3])

## Public API: Collection class
const Collection = preload("res://packages/collection/types/collection.gd")

