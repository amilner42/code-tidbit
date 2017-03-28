module Pages.Init exposing (init)

import Models.Route as Route
import Navigation
import Pages.DefaultModel exposing (..)
import Pages.Messages exposing (..)
import Pages.Model exposing (..)
import Pages.Update exposing (..)


{-| `Base` init.
-}
init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        route =
            Maybe.withDefault
                Route.BrowsePage
                (Route.parseLocation location)

        defaultModelWithRoute : Model
        defaultModelWithRoute =
            { defaultModel
                | shared =
                    { defaultShared
                        | route = route
                    }
            }
    in
        updateCacheIf LoadModelFromLocalStorage defaultModelWithRoute False
