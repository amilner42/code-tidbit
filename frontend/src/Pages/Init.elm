module Pages.Init exposing (init)

import Pages.Messages exposing (Msg(..))
import Pages.Model exposing (Model)
import Pages.Update exposing (updateCacheIf)
import DefaultModel exposing (defaultModel, defaultShared)
import Models.Route as Route
import Navigation


{-| Base Component Init.
-}
init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        route =
            Maybe.withDefault
                Route.HomeComponentBrowse
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
