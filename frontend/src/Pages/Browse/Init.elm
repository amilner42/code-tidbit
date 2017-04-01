module Pages.Browse.Init exposing (..)

import Pages.Browse.Model exposing (..)


{-| `Browse` init.
-}
init : Model
init =
    { content = Nothing
    , pageNumber = 1
    }
