module Pages.ViewStory.Model exposing (..)

import Models.Opinion exposing (PossibleOpinion)


{-| `ViewStory` model.
-}
type alias Model =
    { possibleOpinion : Maybe PossibleOpinion
    }
