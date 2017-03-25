module Pages.ViewSnipbit.Model exposing (..)

import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Models.Completed as Completed
import Models.HighlightedComment as HC
import Models.Snipbit as Snipbit
import Models.ViewerRelevantHC as ViewerRelevantHC


{-| `ViewSnipbit` model.
-}
type alias Model =
    { viewingSnipbit : Maybe Snipbit.Snipbit
    , viewingSnipbitIsCompleted : Maybe Completed.IsCompleted
    , viewingSnipbitRelevantHC : Maybe ViewingSnipbitRelevantHC
    }


{-| Used when viewing a snipbit and the user highlights part of the code.
-}
type alias ViewingSnipbitRelevantHC =
    ViewerRelevantHC.ViewerRelevantHC HC.HighlightedComment


{-| `viewingSnipbit` field updater.
-}
updateViewingSnipbit : (Snipbit.Snipbit -> Snipbit.Snipbit) -> Model -> Model
updateViewingSnipbit updater model =
    { model
        | viewingSnipbit = Maybe.map updater model.viewingSnipbit
    }


{-| `viewingSnipbitIsCompleted` field updater.
-}
updateViewingSnipbitIsCompleted : (Completed.IsCompleted -> Completed.IsCompleted) -> Model -> Model
updateViewingSnipbitIsCompleted updater model =
    { model
        | viewingSnipbitIsCompleted = Maybe.map updater model.viewingSnipbitIsCompleted
    }


{-| `viewingSnipbitRelevantHC` field updater.
-}
updateViewingSnipbitRelevantHC : (ViewingSnipbitRelevantHC -> ViewingSnipbitRelevantHC) -> Model -> Model
updateViewingSnipbitRelevantHC updater model =
    { model
        | viewingSnipbitRelevantHC = Maybe.map updater model.viewingSnipbitRelevantHC
    }


{-| `viewingSnipbit` field setter.
-}
setViewingSnipbit : Maybe Snipbit.Snipbit -> Model -> Model
setViewingSnipbit maybeSnipbit model =
    { model
        | viewingSnipbit = maybeSnipbit
    }


{-| `viewingSnipbitIsCompleted` field setter.
-}
setViewingSnipbitIsCompleted : Maybe Completed.IsCompleted -> Model -> Model
setViewingSnipbitIsCompleted maybeIsCompleted model =
    { model
        | viewingSnipbitIsCompleted = maybeIsCompleted
    }


{-| `viewingSnipbitRelevantHC` field setter.
-}
setViewingSnipbitRelevantHC : Maybe ViewingSnipbitRelevantHC -> Model -> Model
setViewingSnipbitRelevantHC maybeRelevantHC model =
    { model
        | viewingSnipbitRelevantHC = maybeRelevantHC
    }


{-| Returns true if the user is browsing the snipbit viewer relevant HC.
-}
isViewSnipbitRHCTabOpen : Model -> Bool
isViewSnipbitRHCTabOpen model =
    maybeMapWithDefault
        ViewerRelevantHC.browsingFrames
        False
        model.viewingSnipbitRelevantHC
