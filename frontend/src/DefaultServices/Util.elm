module DefaultServices.Util exposing (..)

import Date
import Dict
import Dom
import Elements.Markdown exposing (githubMarkdown)
import Html exposing (Html, Attribute, div, i, text)
import Html.Attributes exposing (hidden, class)
import Html.Events exposing (Options, on, onWithOptions, keyCode, defaultOptions)
import Html.Keyed as Keyed
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard.Extra as KK
import Set
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


{-| Event handler for handling `keyDown` events.
-}
onKeydownWithOptions : Options -> (KK.Key -> Maybe msg) -> Attribute msg
onKeydownWithOptions options keyToMsg =
    let
        decodeMsgFromKeyCode code =
            KK.fromCode code
                |> keyToMsg
                |> maybeMapWithDefault Decode.succeed (Decode.fail "")
    in
        onWithOptions
            "keydown"
            options
            (Decode.andThen decodeMsgFromKeyCode keyCode)


{-| Default event handler for `keyDown` events.
-}
onKeydown : (KK.Key -> Maybe msg) -> Attribute msg
onKeydown =
    onKeydownWithOptions defaultOptions


{-| Event handler for `keyDown` events that also `preventDefault`.

WARNING: It'll only prevent default if your function returns a message not `Nothing`.
-}
onKeydownPreventDefault : (KK.Key -> Maybe msg) -> Attribute msg
onKeydownPreventDefault =
    onKeydownWithOptions
        { preventDefault = True
        , stopPropagation = False
        }


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


{-| Given a bunch of maybe query params, turns it into a string of the query params that are actually there.

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


{-| Date decoder.

NOTE: Will decode both dates in number-form and dates in ISO-string-form.
-}
dateDecoder : Decode.Decoder Date.Date
dateDecoder =
    let
        decodeStringDate =
            Decode.string
                |> Decode.andThen
                    (Date.fromString
                        >> Result.map Decode.succeed
                        >> Result.withDefault (Decode.fail "Error parsing date")
                    )

        decodeFloatDate =
            Decode.float
                |> Decode.map Date.fromTime
    in
        Decode.oneOf
            [ decodeFloatDate, decodeStringDate ]


{-| Encodes a date into number-form.

NOTE: Compatible with `dateDecoder`.
-}
dateEncoder : Date.Date -> Encode.Value
dateEncoder =
    Encode.float << Date.toTime


{-| Sorts a list by the date.
-}
sortByDate : (x -> Date.Date) -> List x -> List x
sortByDate getDate =
    List.sortBy (getDate >> Date.toTime)


{-| Produces a keyed div.
-}
keyedDiv : List (Attribute msg) -> List ( String, Html msg ) -> Html msg
keyedDiv =
    Keyed.node "div"


{-| Returns `Just` the element at the given index in the list, or `Nothing` if the list is not long enough.
-}
getAt : List a -> Int -> Maybe a
getAt xs idx =
    List.head <| List.drop idx xs


{-| Get's the index of the first `False` in a list, otherwise returns `Nothing` if the list does not contain a single
`False`.
-}
indexOfFirstFalse : List Bool -> Maybe Int
indexOfFirstFalse =
    let
        go index listOfBool =
            case listOfBool of
                [] ->
                    Nothing

                h :: xs ->
                    if not h then
                        Just index
                    else
                        go (index + 1) xs
    in
        go 0


{-| When running multiple updates, it can be cleaner aesthetically to have it as one list as opposed to using pipes.
-}
multipleUpdates : List (a -> a) -> (a -> a)
multipleUpdates =
    List.foldl (>>) identity


{-| For adding a string to a list of strings if it's not empty and it's also not already in the list.
-}
addUniqueNonEmptyString : String -> List String -> List String
addUniqueNonEmptyString stringToAdd listOfStrings =
    if String.isEmpty stringToAdd || List.member stringToAdd listOfStrings then
        listOfStrings
    else
        stringToAdd :: listOfStrings


{-| A semi-hack for flex-box justify-center but align-left.

@REFER http://stackoverflow.com/questions/18744164/flex-box-align-last-row-to-grid
-}
emptyFlexBoxesForAlignment : List (Html msg)
emptyFlexBoxesForAlignment =
    List.repeat 10 <| div [ class "empty-tidbit-box-for-flex-align" ] []


{-| Renders markdown if condition is true, otherwise the backup html.
-}
markdownOr : Bool -> String -> Html msg -> Html msg
markdownOr condition markdownText backUpHtml =
    if condition then
        githubMarkdown [] markdownText
    else
        backUpHtml


{-| Helper for flipping the previewMarkdown field of any record.
-}
togglePreviewMarkdown : { a | previewMarkdown : Bool } -> { a | previewMarkdown : Bool }
togglePreviewMarkdown record =
    { record | previewMarkdown = not record.previewMarkdown }
