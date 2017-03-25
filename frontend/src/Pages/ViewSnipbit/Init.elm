module Pages.ViewSnipbit.Init exposing (..)

import Pages.ViewSnipbit.Model exposing (Model)


{-| `ViewSnipbit` init.
-}
init : Model
init =
    { viewingSnipbit = Nothing
    , viewingSnipbitIsCompleted = Nothing
    , viewingSnipbitRelevantHC = Nothing
    }
