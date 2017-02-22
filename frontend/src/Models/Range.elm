module Models.Range exposing (..)

import Array
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode


{-| A range selected inside a code editor.
-}
type alias Range =
    { startRow : Int
    , endRow : Int
    , startCol : Int
    , endCol : Int
    }


{-| Range `cacheDecoder`.
-}
rangeCacheDecoder : Decode.Decoder Range
rangeCacheDecoder =
    Decode.map4 Range
        (Decode.field "startRow" Decode.int)
        (Decode.field "endRow" Decode.int)
        (Decode.field "startCol" Decode.int)
        (Decode.field "endCol" Decode.int)


{-| Range `cacheEncoder`.
-}
rangeCacheEncoder : Range -> Encode.Value
rangeCacheEncoder record =
    Encode.object
        [ ( "startRow", Encode.int <| record.startRow )
        , ( "endRow", Encode.int <| record.endRow )
        , ( "startCol", Encode.int <| record.startCol )
        , ( "endCol", Encode.int <| record.endCol )
        ]


{-| Checks if a range is empty.
-}
isEmptyRange : Range -> Bool
isEmptyRange range =
    (range.startRow == range.endRow)
        && (range.startCol == range.endCol)


{-| Similar to `isEmptyRange` but returning range allowing for better chaining.
-}
nonEmptyRangeOrNothing : Range -> Maybe Range
nonEmptyRangeOrNothing range =
    if isEmptyRange range then
        Nothing
    else
        Just range


{-| Checks that a range is still in range for some given code, if it is, returns
the same range. If the range is now out of range because the code has been
shortened, returns the maximum size range that is in range. If a range is now
completely out of range then it will end up returning an empty range on
the last possible line.
-}
newValidRange : Range -> String -> Range
newValidRange range newCode =
    let
        rowsOfCode =
            String.split "\n" newCode

        maxRow =
            List.length rowsOfCode - 1

        lastRow =
            Util.lastElem rowsOfCode

        maxCol =
            case lastRow of
                Nothing ->
                    0

                Just lastRowString ->
                    String.length lastRowString

        {- Gets the new col and row in range checked against `maxRow` and
           `maxCol`.
        -}
        getNewColAndRow : Int -> Int -> ( Int, Int )
        getNewColAndRow currentRow currentCol =
            if currentRow < maxRow then
                ( currentRow, currentCol )
            else if currentRow == maxRow then
                ( currentRow, min currentCol maxCol )
            else
                ( maxRow, maxCol )

        ( newStartRow, newStartCol ) =
            getNewColAndRow range.startRow range.startCol

        ( newEndRow, newEndCol ) =
            getNewColAndRow range.endRow range.endCol
    in
        { startRow = newStartRow
        , startCol = newStartCol
        , endRow = newEndRow
        , endCol = newEndCol
        }


{-| Returns true if `range1` is before `range2` and has absolutey no overlap.
-}
(<<<) : Range -> Range -> Bool
(<<<) range1 range2 =
    (range1.endRow < range2.startRow)
        || (range1.endRow == range2.startRow && range1.endCol <= range2.startCol)


{-| Returns true if `range1` is after `range2` and has absolute no overlap.
-}
(>>>) : Range -> Range -> Bool
(>>>) range1 range2 =
    (range1.startRow > range2.endRow)
        || (range1.startRow == range2.endRow && range1.startCol >= range2.endCol)


{-| Checks if 2 ranges overlap at all.
-}
overlappingRanges : Range -> Range -> Bool
overlappingRanges range1 range2 =
    not <| (range1 <<< range2) || (range1 >>> range2)


{-| Collapses a range in on it's starting point. It will become empty range.
-}
collapseRange : Range -> Range
collapseRange range =
    { startRow = range.startRow
    , endRow = range.startRow
    , startCol = range.startCol
    , endCol = range.startCol
    }


{-| Given some code and a range, returns the one-dimensional cordinates of the
range. This is the number of characters from the left treating the code as one
long string of characters.

NOTE: we do count newlines as characters as well.

WARNING: Assumes the code is valid for the range, does not check and will
produce an incorrect result if the range is not valid for the given code.
-}
toOneDimensionalCordinates : String -> Range -> ( Int, Int )
toOneDimensionalCordinates code range =
    let
        codeAsArray =
            Array.fromList <| String.split "\n" code

        lengthOfRow row =
            Array.get row codeAsArray
                |> Util.maybeMapWithDefault String.length 0

        startCounting : ( Int, Int ) -> Int -> Int -> Int
        startCounting ( row, col ) currentRow currentAcc =
            if currentRow == row then
                currentAcc + col
            else
                startCounting ( row, col ) (currentRow + 1) (1 + currentAcc + (lengthOfRow currentRow))
    in
        ( startCounting ( range.startRow, range.startCol ) 0 0
        , startCounting ( range.endRow, range.endCol ) 0 0
        )


{-| Given some code and 1 dimensional cordinates, returns the range for those
cordinates.

WARNING: Assumes the code is valid for the cordinates, does not check and will
produce an incorrect result if the given cordinates are invalid.
-}
fromOneDimensionalCordinates : String -> ( Int, Int ) -> Range
fromOneDimensionalCordinates code ( start, end ) =
    let
        codeBeforeFirstCordinate =
            String.slice 0 start code

        codeBeforeSecondCordinate =
            String.slice 0 end code

        -- Gets the row and col for the rightmost char in the substring.
        getRowAndColForSubString subString =
            let
                codeAsArray =
                    Array.fromList <| String.split "\n" subString

                -- 0 based indexing.
                row =
                    Array.length codeAsArray - 1

                col =
                    Array.get row codeAsArray
                        |> Util.maybeMapWithDefault String.length 0
            in
                ( row, col )

        ( startRow, startCol ) =
            getRowAndColForSubString codeBeforeFirstCordinate

        ( endRow, endCol ) =
            getRowAndColForSubString codeBeforeSecondCordinate
    in
        { startRow = startRow
        , startCol = startCol
        , endRow = endRow
        , endCol = endCol
        }


{-| Shifts the cordinates by `shiftAmount`.
-}
shiftCordinates : Int -> ( Int, Int ) -> ( Int, Int )
shiftCordinates shiftAmount ( start, end ) =
    ( start + shiftAmount, end + shiftAmount )


{-| Gets the new range after a change has been made in the editor.

NOTE: This originally was a massive pain in the ass, but a shift in the
approach has made it much simpler, we think about the domain in 1 dimension,
do the transformations, and only at the end convert back to the 2 dimensional
matrix. This avoids a lot of nasty code.
-}
getNewRangeAfterDelta : String -> String -> String -> Range -> Range -> Range
getNewRangeAfterDelta oldCode newCode action deltaRange selectedRange =
    let
        (( selectedStartCordinate, selectedEndCordinate ) as selectedCordinates) =
            toOneDimensionalCordinates oldCode selectedRange
    in
        case action of
            "insert" ->
                let
                    -- With insertion, we want to get the 1D cordinates against
                    -- the new code.
                    ( deltaStartCordinate, deltaEndCordinate ) =
                        toOneDimensionalCordinates newCode deltaRange

                    deltaLength =
                        deltaEndCordinate - deltaStartCordinate
                in
                    if deltaStartCordinate <= selectedStartCordinate then
                        fromOneDimensionalCordinates newCode (shiftCordinates deltaLength selectedCordinates)
                    else if deltaStartCordinate < selectedEndCordinate then
                        fromOneDimensionalCordinates newCode ( selectedStartCordinate, selectedEndCordinate + deltaLength )
                    else
                        selectedRange

            "remove" ->
                let
                    -- With removal, we want to get the 1D cordinates against
                    -- the old code, because that's the code we are erasing.
                    ( deltaStartCordinate, deltaEndCordinate ) =
                        toOneDimensionalCordinates oldCode deltaRange

                    deltaLength =
                        deltaEndCordinate - deltaStartCordinate
                in
                    if deltaEndCordinate <= selectedStartCordinate then
                        fromOneDimensionalCordinates newCode (shiftCordinates (-1 * deltaLength) selectedCordinates)
                    else if deltaEndCordinate <= selectedEndCordinate then
                        fromOneDimensionalCordinates
                            newCode
                            ( Basics.min selectedStartCordinate deltaStartCordinate
                            , selectedEndCordinate - deltaLength
                            )
                    else
                        fromOneDimensionalCordinates
                            newCode
                            ( Basics.min selectedStartCordinate deltaStartCordinate
                            , Basics.min selectedEndCordinate deltaStartCordinate
                            )

            -- This will never happen, ACE actions are limited to "insert" and
            -- "remove", otherwise ACE errors internally and never sends it.
            _ ->
                selectedRange
