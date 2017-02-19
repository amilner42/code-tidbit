module DefaultServices.Util exposing (..)

import Dict
import Dom
import Html exposing (Html, Attribute)
import Html.Attributes exposing (hidden)
import Html.Events exposing (on, onWithOptions, keyCode)
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


{-| Attribute for "preventDefault" on tab-keydown.

NOTE: Will succeed with whatever message passed if it's a tab, if we use
`Decode.fail` then the prevent default is not activated. So simply pass a `NoOp`
if you just want the prevent default functionality.
-}
preventTabDefault : msg -> Attribute msg
preventTabDefault msg =
    onWithOptions
        "keydown"
        { stopPropagation = False, preventDefault = True }
        (Decode.andThen
            (\code ->
                if code == 9 then
                    Decode.succeed msg
                else
                    Decode.fail "Not a tab"
            )
            keyCode
        )


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


{-| Helper for encoding dictionaries which use strings as keys.
-}
encodeStringDict : (v -> Encode.Value) -> Dict.Dict String v -> Encode.Value
encodeStringDict valueEncoder dict =
    Dict.toList dict
        |> List.map (\( k, v ) -> ( k, valueEncoder v ))
        |> Encode.object


{-| Helper for decoding dictionaries which use strings as keys.
-}
decodeStringDict : Decode.Decoder v -> Decode.Decoder (Dict.Dict String v)
decodeStringDict decodeValue =
    Decode.keyValuePairs decodeValue
        |> Decode.map Dict.fromList


{-| Creates a basic hidden div.
-}
hiddenDiv : Html.Html msg
hiddenDiv =
    Html.div [ hidden True ] []


{-| Helper for converting errors to False and successes to True.
-}
resultToBool : Result a b -> Bool
resultToBool result =
    case result of
        Err _ ->
            False

        Ok _ ->
            True


{-| Given a bunch of maybe query params, turns it into a string of the query
params that are actually there.

Eg.
  []  -> ""
  [("path", Just "asdf"), ("bla", Nothing)] -> "?path=asdf"
  [("path", Just "asdf"), ("bla", Just "bla")] -> "?path=asdf&bla=bla"

-}
queryParamsToString : List ( String, Maybe String ) -> String
queryParamsToString listOfMaybeQueryParams =
    listOfMaybeQueryParams
        |> List.foldl
            (\( qpName, maybeQPValue ) currentQPString ->
                case maybeQPValue of
                    Nothing ->
                        currentQPString

                    Just qpValue ->
                        currentQPString ++ (qpName ++ "=" ++ qpValue ++ "&")
            )
            "?"
        |> String.dropRight 1


{-| If the string is empty returns `Nothing`, otherwise `Just` the string.
-}
justNonEmptyString : String -> Maybe String
justNonEmptyString string =
    if String.isEmpty string then
        Nothing
    else
        Just string


{-| If the list is empty, returns `Nothing`, otherwise `Just` the list.
-}
justNonEmptyList : List a -> Maybe (List a)
justNonEmptyList listOfA =
    if List.isEmpty listOfA then
        Nothing
    else
        Just listOfA


{-| Convenience helper for avoiding Maybe.map followed by `withDefault`.
-}
maybeMapWithDefault : (a -> b) -> b -> Maybe a -> b
maybeMapWithDefault func default maybeA =
    Maybe.map func maybeA
        |> Maybe.withDefault default
