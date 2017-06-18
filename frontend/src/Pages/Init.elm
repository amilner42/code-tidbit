module Pages.Init exposing (init)

import Flags exposing (Flags)
import Models.Route as Route
import Navigation
import Pages.DefaultModel exposing (..)
import Pages.Messages exposing (..)
import Pages.Model exposing (..)
import Pages.Update exposing (..)


{-| `Base` init.
-}
init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        route =
            Maybe.withDefault
                Route.BrowsePage
                (Route.parseLocation location)

        defaultModelWithRoute : Model
        defaultModelWithRoute =
            defaultModel route flags
    in
    updateCacheIf LoadModelFromLocalStorage defaultModelWithRoute False
