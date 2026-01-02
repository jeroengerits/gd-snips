## Public API entry point for the Collection package.
##
## Barrel file that exports the Collection class.
## Use this to import the Collection class:
##
##   const CollectionPackage = preload("res://packages/collection/collection_package.gd")
##   var collection = CollectionPackage.Collection.new([1, 2, 3])
##
## Or import directly:
##   const Collection = preload("res://packages/collection/collection.gd")
##   var collection = Collection.new([1, 2, 3])

## Public API: Collection class
const Collection = preload("res://packages/collection/collection.gd")

