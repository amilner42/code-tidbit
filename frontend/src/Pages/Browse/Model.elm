module Pages.Browse.Model exposing (..)

import Models.Content exposing (Content)


{-| `Browse` model.
-}
type alias Model =
    { content : Maybe (List Content)
    , pageNumber : Int
    }
