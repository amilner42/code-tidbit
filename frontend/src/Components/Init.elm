module Components.Init exposing (init)

import Components.Messages exposing (Msg(..))
import Components.Model exposing (Model)
import Components.Update exposing (updateCacheIf)
import DefaultModel exposing (defaultModel, defaultShared)
import Models.Route as Route
import Navigation
import Router


{-| Base Component Init.
-}
init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        route =
            Maybe.withDefault
                Route.HomeComponentBrowse
                (Router.parseLocation location)

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
