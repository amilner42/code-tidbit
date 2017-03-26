module Pages.ViewSnipbit.Init exposing (..)

import Pages.ViewSnipbit.Model exposing (..)


{-| `ViewSnipbit` init.
-}
init : Model
init =
    { snipbit = Nothing
    , isCompleted = Nothing
    , relevantHC = Nothing
    }
