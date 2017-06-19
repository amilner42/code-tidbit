module DefaultServices.TextFields exposing (..)

{-| Module for wrapping `input`/`textarea` to avoid the cursor-jump bug.
-}

import DefaultServices.InfixFunctions exposing (..)
import Dict
import Html
import Html.Keyed


{-| The Key used on the `Html.Keyed` child node.
-}
type alias Key =
    String


{-| A counter connected to a specific `Key`.
-}
type alias KeyCounter =
    Int


{-| Tracks all the `Key`s and their respective `KeyCounter`s.
-}
type alias KeyTracker =
    Dict.Dict Key KeyCounter


{-| A wrapper around `textarea` which uses `Html.Keyed`.

Use `defaultValue` instead of `value` to avoid cursor bugs. If you need to update the text through Elm and have it be reflected
in the textarea, then use `makeKey` to generate the `Key` and run `changeKey` everytime you want it to update.

-}
textarea : Key -> List (Html.Attribute msg) -> Html.Html msg
textarea key attributes =
    Html.Keyed.node "div" [] [ ( key, Html.textarea attributes [] ) ]


{-| A wrapper around `input` which uses `Html.Keyed`.

Use `defaultValue` instead of `value` to avoid cursor bugs. If you need to update the text through Elm and have it be reflected
in the input, then use `makeKey` to generate the `Key` and run `changeKey` everytime you want it to update.

-}
input : Key -> List (Html.Attribute msg) -> Html.Html msg
input key attributes =
    Html.Keyed.node "div" [] [ ( key, Html.input attributes [] ) ]


{-| Makes a key given the `KeyTracker` and the `Key`.
-}
makeKey : KeyTracker -> Key -> Key
makeKey keyTracker key =
    Dict.get key keyTracker
        ?> 0
        |> (\counter -> key ++ "-" ++ toString counter)


{-| Updates the counter for a key to change the result of `makeKey`.
-}
changeKey : KeyTracker -> Key -> KeyTracker
changeKey keyTracker key =
    Dict.update
        key
        (\keyInt ->
            keyInt
                ?> 0
                |> (+) 1
                |> Just
        )
        keyTracker
