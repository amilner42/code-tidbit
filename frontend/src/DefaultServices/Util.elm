module DefaultServices.Util exposing (..)

import Date
import DefaultServices.InfixFunctions exposing (..)
import Dict
import Dom
import Elements.Simple.Markdown as Markdown
import Html exposing (Attribute, Html, a, div, i, text)
import Html.Attributes exposing (class, hidden, href)
import Html.Events exposing (Options, defaultOptions, keyCode, on, onWithOptions, targetValue)
import Html.Keyed as Keyed
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard.Extra as KK
import ProjectTypeAliases exposing (..)
import Regex
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


{-| For watching for `onChange` events.
-}
onChange : (String -> msg) -> Attribute msg
onChange tagger =
    on "change" (Decode.map tagger targetValue)


{-| Similar to `onClick`, but prevents event propogation.
-}
onClickWithoutPropigation : msg -> Attribute msg
onClickWithoutPropigation msg =
    onWithOptions "click" { defaultOptions | stopPropagation = True } (Decode.succeed msg)


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


{-| Decodes a pair from javascript (which comes as an array).
-}
decodePair : Decode.Decoder a -> Decode.Decoder b -> Decode.Decoder ( a, b )
decodePair decodeA decodeB =
    Decode.map2 (,) (Decode.index 0 decodeA) (Decode.index 1 decodeB)


{-| Encodes a pair into javascript-pair-format (array).
-}
encodePair : (a -> Encode.Value) -> (b -> Encode.Value) -> ( a, b ) -> Encode.Value
encodePair encodeA encodeB ( a, b ) =
    Encode.list [ encodeA a, encodeB b ]


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
[] -> ""
[("path", Just "asdf"), ("bla", Nothing)] -> "?path=asdf"
[("path", Just "asdf"), ("bla", Just "bla")] -> "?path=asdf&bla=bla"

-}
queryParamsToString : QueryParams -> String
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


{-| For converting Elm booleans to javascript booleans (useful in query params for instance).
-}
toJSBool : Bool -> String
toJSBool bool =
    if bool then
        "true"
    else
        "false"


{-| If the string is empty returns `Nothing`, otherwise `Just` the string.
-}
justNonEmptyString : String -> Maybe String
justNonEmptyString string =
    if String.isEmpty string then
        Nothing
    else
        Just string


{-| Returns true if a string is empty or just spaces and newlines.
-}
isBlankString : String -> Bool
isBlankString =
    String.isEmpty << String.filter (\char -> char /= ' ' && char /= '\n')


{-| Checks that an email has valid characters.

@refer <https://github.com/rtfeldman/elm-validate/blob/master/src/Validate.elm#L135>

-}
isValidEmail : String -> Bool
isValidEmail =
    let
        validEmail =
            Regex.regex "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
                |> Regex.caseInsensitive
    in
    Regex.contains validEmail


{-| If the string is blank returns `Nothing`, otherwise `Just` the string.

@refer `isBlankString`

-}
justNonBlankString : String -> Maybe String
justNonBlankString string =
    if isBlankString string then
        Nothing
    else
        Just string


{-| If the string is in the range (inclusive) then returns `Just` the string, otherwise `Nothing`.
-}
justStringInRange : Int -> Int -> String -> Maybe String
justStringInRange lower upper string =
    let
        stringLength =
            String.length string
    in
    if (stringLength >= lower) && (stringLength <= upper) then
        Just string
    else
        Nothing


{-| Checks that a string isn't blank and is within a specific range.

@refer `justStringInRange`
@refer `justNonBlankString`

-}
justNonblankStringInRange : Int -> Int -> String -> Maybe String
justNonblankStringInRange lower upper string =
    justStringInRange lower upper string |||> justNonBlankString


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

@REFER <http://stackoverflow.com/questions/18744164/flex-box-align-last-row-to-grid>

-}
emptyFlexBoxesForAlignment : List (Html msg)
emptyFlexBoxesForAlignment =
    List.repeat 10 <| div [ class "empty-tidbit-box-for-flex-align" ] []


{-| Renders markdown if condition is true, otherwise the backup html.
-}
markdownOr : Bool -> String -> Html msg -> Html msg
markdownOr condition markdownText backUpHtml =
    if condition then
        Markdown.view [] markdownText
    else
        backUpHtml


{-| Helper for flipping the previewMarkdown field of any record.
-}
togglePreviewMarkdown : { a | previewMarkdown : Bool } -> { a | previewMarkdown : Bool }
togglePreviewMarkdown record =
    { record | previewMarkdown = not record.previewMarkdown }


{-| For pluralizing words if there isn't just 1 thing.

xThings "thing" "s" 1 = "1 thing"
xThings "thing" "s" 3 = "3 things"

-}
xThings : String -> String -> Int -> String
xThings baseWord suffix number =
    toString number
        ++ " "
        ++ (if number == 1 then
                baseWord
            else
                baseWord ++ suffix
           )


{-| For generating a `div.char-count` with the "<length-of-text> / <text-limit>" string.
-}
limitCharsText : Int -> String -> Html msg
limitCharsText limit string =
    div
        [ class "char-count" ]
        [ text <| (toString <| String.length string) ++ " / " ++ toString limit ]


{-| Similar to `classList`, but for attributes, and using `Maybe` instead of a tuple.
-}
maybeAttributes : List (Maybe (Attribute msg)) -> List (Attribute msg)
maybeAttributes =
    List.filterMap identity


{-| For an onClick event which prevents the click default (so we can handle nav in the SPA) but allows ctrl/cmd click
so that it can be opened in a new tab (without being prevented).

Copied (and slightly modified) from github issue: <https://github.com/elm-lang/html/issues/110>

-}
onClickPreventDefault : msg -> Attribute msg
onClickPreventDefault message =
    let
        invertedOr : Bool -> Bool -> Bool
        invertedOr x y =
            not (x || y)

        maybePreventDefault : msg -> Bool -> Decode.Decoder msg
        maybePreventDefault msg preventDefault =
            case preventDefault of
                True ->
                    Decode.succeed msg

                False ->
                    Decode.fail "Normal link"

        preventDefault2 : Decode.Decoder Bool
        preventDefault2 =
            Decode.map2
                invertedOr
                (Decode.field "ctrlKey" Decode.bool)
                (Decode.field "metaKey" Decode.bool)
    in
    onWithOptions "click"
        { defaultOptions | preventDefault = True }
        (preventDefault2
            |> Decode.andThen (maybePreventDefault message)
        )
