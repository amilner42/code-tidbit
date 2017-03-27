module Pages.Create.Model exposing (..)

import Models.TidbitType as TidbitType


{-| `Create` model.
-}
type alias Model =
    { showInfoFor : Maybe TidbitType.TidbitType
    }


{-| Sets `showInfoFor`.
-}
setShowInfoFor : Maybe TidbitType.TidbitType -> Model -> Model
setShowInfoFor maybeTidbitType model =
    { model | showInfoFor = maybeTidbitType }
