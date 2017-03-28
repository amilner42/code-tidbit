module Elements.ProgressBar exposing (..)

import DefaultServices.Util as Util
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList, style)


{-| Builds a progress bar

NOTE: If position is `Nothing`, it is assumed 0% is complete.
-}
progressBar : Maybe Int -> Int -> Bool -> Html msg
progressBar maybePosition maxPosition isDisabled =
    let
        percentComplete =
            case maybePosition of
                Nothing ->
                    0

                Just currentFrame ->
                    100 * (toFloat currentFrame) / (toFloat maxPosition)
    in
        div
            [ classList
                [ ( "progress-bar", True )
                , ( "selected", Util.isNotNothing maybePosition )
                , ( "disabled", isDisabled )
                ]
            ]
            [ div
                [ classList
                    [ ( "progress-bar-completion-bar", True )
                    , ( "disabled", isDisabled )
                    ]
                , style [ ( "width", (toString <| round <| percentComplete * 1.6) ++ "px" ) ]
                ]
                []
            , div
                [ class "progress-bar-percent" ]
                [ text <| (toString <| round <| percentComplete) ++ "%" ]
            ]
