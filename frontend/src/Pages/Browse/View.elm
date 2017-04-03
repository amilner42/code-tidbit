module Pages.Browse.View exposing (..)

import DefaultServices.Util as Util
import Elements.ContentBox exposing (contentBox)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Pages.Browse.Messages exposing (..)
import Pages.Browse.Model exposing (..)
import Pages.Model exposing (Shared)


{-| `Browse` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    case model.content of
        Nothing ->
            Util.hiddenDiv

        Just content ->
            div
                [ class "browse-page" ]
                ((List.map contentBox content) ++ Util.emptyFlexBoxesForAlignment)
