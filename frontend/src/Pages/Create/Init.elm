module Pages.Create.Init exposing (..)

import Models.TidbitType as TidbitType
import Pages.Create.Model exposing (..)


{-| `Create` init.
-}
init : Model
init =
    { showInfoFor = Nothing
    }
