module Pages.Notifications.View exposing (..)

import DefaultServices.Util as Util
import Html exposing (Html, div, text)
import Pages.Model exposing (Shared)
import Pages.Notifications.Messages exposing (..)
import Pages.Notifications.Model exposing (..)


{-| `Notifications` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    div
        []
        [ case model.notifications of
            Nothing ->
                Util.hiddenDiv

            Just notifications ->
                text "fetched"
        ]
