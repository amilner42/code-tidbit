module DefaultServices.ArrayExtra exposing (..)

import Array


{-| Updates an item in the array at position `index` if it exists, otherwise,
returns the same array.
-}
update : Int -> Array.Array item -> (item -> item) -> Array.Array item
update index array updater =
    case Array.get index array of
        Nothing ->
            array

        Just itemAtIndex ->
            let
                newItemAtIndex =
                    updater itemAtIndex
            in
                Array.set
                    index
                    newItemAtIndex
                    array
