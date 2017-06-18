module Models.ContentPointer exposing (..)

{-| -}


{-| A way of pointing to specific content.

Parallels to a `ContentPointer` from the backend.

-}
type alias ContentPointer =
    { contentType : ContentType
    , contentID : String
    }


{-| The different `ContentType`s

Parallels directly to `ContentType` enum on the backend.

-}
type ContentType
    = Snipbit
    | Bigbit
    | Story
