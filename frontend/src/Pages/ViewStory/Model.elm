module Pages.ViewStory.Model exposing (..)

import Models.Opinion exposing (MaybeOpinion)


{-| `ViewStory` model.
-}
type alias Model =
    { maybeOpinion : Maybe MaybeOpinion
    }
