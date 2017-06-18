module Elements.Simple.ProgressBar exposing (..)

import DefaultServices.Util as Util
import Html exposing (Html, div, i, text)
import Html.Attributes exposing (class, classList, style)
import Html.Events exposing (onClick)


{-| The possible states of the progress bar.
-}
type State
    = NotStarted
    | Started Int
    | Completed


{-| Returns true if the state is `Started`.
-}
isStartedState : State -> Bool
isStartedState state =
    case state of
        Started _ ->
            True

        _ ->
            False


{-| Returns true if the state is `Completed`.
-}
isCompletedState : State -> Bool
isCompletedState state =
    case state of
        Completed ->
            True

        _ ->
            False


{-| The different text formats to use in the progress bar.
-}
type TextFormat
    = Percentage
    | Custom { notStarted : String, started : Int -> String, done : String }


{-| We apply different styling depending on what's completed.
-}
type CompletedFor
    = Tidbit
    | Story


{-| For specifying whether a user has already fully finished a tidbit/story.
-}
type alias CompleteConfig =
    { complete : Bool, for : CompletedFor }


{-| NOTE: `shiftLeft` will make the `Completed` state 100% of the bar and x/x frames will render (x-1/x)% of the bar.
-}
type alias RenderConfig msg =
    { state : State
    , maxPosition : Int
    , disabledStyling : Bool
    , onClickMsg : msg
    , allowClick : Bool
    , textFormat : TextFormat
    , shiftLeft : Bool
    , alreadyComplete : CompleteConfig
    }


view : RenderConfig msg -> Html msg
view { state, maxPosition, disabledStyling, onClickMsg, allowClick, textFormat, shiftLeft, alreadyComplete } =
    let
        percentComplete =
            case state of
                NotStarted ->
                    0

                Started currentFrame ->
                    if shiftLeft then
                        100 * (toFloat currentFrame - 1) / toFloat maxPosition
                    else
                        100 * toFloat currentFrame / toFloat maxPosition

                Completed ->
                    100
    in
    div
        ([ classList
            [ ( "progress-bar", True )
            , ( "selected", isStartedState state )
            , ( "completed", isCompletedState state )
            , ( "disabled", disabledStyling )
            , ( "click-allowed", allowClick )
            ]
         ]
            ++ (if allowClick then
                    [ onClick onClickMsg ]
                else
                    []
               )
        )
        [ div
            [ classList
                [ ( "progress-bar-completion-bar", True )
                , ( "disabled", disabledStyling )
                ]
            , style [ ( "width", (toString <| round <| percentComplete * 1.6) ++ "px" ) ]
            ]
            []
        , div
            []
            [ text <|
                case textFormat of
                    Percentage ->
                        (toString <| round <| percentComplete) ++ "%"

                    Custom { notStarted, started, done } ->
                        case state of
                            NotStarted ->
                                notStarted

                            Started currentFrame ->
                                started currentFrame

                            Completed ->
                                done
            ]
        , div
            [ classList
                [ ( "completion-symbol", True )
                , ( "hidden", not alreadyComplete.complete )
                , ( "for-story"
                  , case alreadyComplete.for of
                        Story ->
                            True

                        _ ->
                            False
                  )
                ]
            ]
            [ i [ class "material-icons" ]
                [ text <|
                    case alreadyComplete.for of
                        Story ->
                            "done_all"

                        Tidbit ->
                            "done"
                ]
            ]
        ]
