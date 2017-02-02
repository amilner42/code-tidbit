module DefaultServices.Util exposing (..)

import Dom
import Html exposing (Html, Attribute)
import Html.Events exposing (on, keyCode)
import Json.Decode as Decode
import Json.Encode as Encode
import Task


{-| Useful for encoding, turns maybes into nulls / there actual value.
-}
justValueOrNull : (a -> Encode.Value) -> Maybe a -> Encode.Value
justValueOrNull somethingToEncodeValue maybeSomething =
    case maybeSomething of
        Nothing ->
            Encode.null

        Just something ->
            somethingToEncodeValue something


{-| Result or ...
-}
resultOr : Result a b -> b -> b
resultOr result default =
    case result of
        Ok valueB ->
            valueB

        Err valueA ->
            default


{-| Returns true if `a` is nothing.
-}
isNothing : Maybe a -> Bool
isNothing maybeValue =
    case maybeValue of
        Nothing ->
            True

        Just something ->
            False


{-| Returns true if `a` is not nothing.
-}
isNotNothing : Maybe a -> Bool
isNotNothing maybeValue =
    not <| isNothing <| maybeValue


{-| Turn a string into a record using a decoder.
-}
fromJsonString : Decode.Decoder a -> String -> Result String a
fromJsonString decoder encodedString =
    Decode.decodeString decoder encodedString


{-| Turn a record into a string using an encoder.
-}
toJsonString : (a -> Encode.Value) -> a -> String
toJsonString encoder record =
    Encode.encode 0 (encoder record)


{-| Wraps a string in "quotes".
-}
quote : String -> String
quote word =
    "\"" ++ word ++ "\""


{-| Event handler for enter clicks.
-}
onEnter : msg -> Attribute msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Decode.succeed msg
            else
                Decode.fail "not ENTER"
    in
        on "keydown" (Decode.andThen isEnter keyCode)


{-| Gets the last element of a list, if list is empty then Nothing.
-}
lastElem : List a -> Maybe a
lastElem =
    List.foldl (Just >> always) Nothing


{-| For turning a msg into a command.
-}
cmdFromMsg : msg -> Cmd msg
cmdFromMsg msg =
    Task.perform
        (\_ -> msg)
        (Task.succeed "")


{-| Focus on a DOM element.
-}
domFocus : (Result.Result Dom.Error () -> msg) -> String -> Cmd msg
domFocus onFocus domElement =
    Task.attempt onFocus (Dom.focus domElement)
