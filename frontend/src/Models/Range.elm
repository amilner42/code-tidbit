module Models.Range exposing (..)

import Array
import DefaultServices.Util as Util


{-| A range selected inside a code editor.
-}
type alias Range =
    { startRow : Int
    , endRow : Int
    , startCol : Int
    , endCol : Int
    }


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


{-| Checks that a range is still in range for some given code, if it is, returns the same range. If the range is now out
of range because the code has been shortened, returns the maximum size range that is in range. If a range is now
completely out of range then it will end up returning an empty range on the last possible line.
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

        {- Gets the new col and row in range checked against `maxRow` and `maxCol`. -}
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


{-| Given some code and a range, returns the one-dimensional coordinates of the range. This is the number of characters
from the left treating the code as one long string of characters.

NOTE: We do count newlines as characters.

WARNING: Assumes the code is valid for the range, does not check and will produce an incorrect result if the range is
not valid for the given code.

-}
toOneDimensionalCoordinates : String -> Range -> ( Int, Int )
toOneDimensionalCoordinates code range =
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
                startCounting ( row, col ) (currentRow + 1) (1 + currentAcc + lengthOfRow currentRow)
    in
    ( startCounting ( range.startRow, range.startCol ) 0 0
    , startCounting ( range.endRow, range.endCol ) 0 0
    )


{-| Given some code and 1 dimensional coordinates, returns the range for those coordinates.

WARNING: Assumes the code is valid for the coordinates, does not check and will produce an incorrect result if the given
coordinates are invalid.

-}
fromOneDimensionalCoordinates : String -> ( Int, Int ) -> Range
fromOneDimensionalCoordinates code ( start, end ) =
    let
        codeBeforeFirstCoordinate =
            String.slice 0 start code

        codeBeforeSecondCoordinate =
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
            getRowAndColForSubString codeBeforeFirstCoordinate

        ( endRow, endCol ) =
            getRowAndColForSubString codeBeforeSecondCoordinate
    in
    { startRow = startRow
    , startCol = startCol
    , endRow = endRow
    , endCol = endCol
    }


{-| Shifts the coordinates by `shiftAmount`.
-}
shiftCoordinates : Int -> ( Int, Int ) -> ( Int, Int )
shiftCoordinates shiftAmount ( start, end ) =
    ( start + shiftAmount, end + shiftAmount )


{-| Gets the new range after a change has been made in the editor.

NOTE: This originally was a massive pain in the ass, but a shift in the approach has made it much simpler, we think
about the domain in 1 dimension, do the transformations, and only at the end convert back to the 2 dimensional
matrix. This avoids a lot of nasty code.

-}
getNewRangeAfterDelta : String -> String -> String -> Range -> Range -> Range
getNewRangeAfterDelta oldCode newCode action deltaRange selectedRange =
    let
        (( selectedStartCoordinate, selectedEndCoordinate ) as selectedCoordinates) =
            toOneDimensionalCoordinates oldCode selectedRange
    in
    case action of
        "insert" ->
            let
                -- With insertion, we want to get the 1D coordinates against the new code.
                ( deltaStartCoordinate, deltaEndCoordinate ) =
                    toOneDimensionalCoordinates newCode deltaRange

                deltaLength =
                    deltaEndCoordinate - deltaStartCoordinate
            in
            if deltaStartCoordinate <= selectedStartCoordinate then
                fromOneDimensionalCoordinates newCode (shiftCoordinates deltaLength selectedCoordinates)
            else if deltaStartCoordinate < selectedEndCoordinate then
                fromOneDimensionalCoordinates newCode ( selectedStartCoordinate, selectedEndCoordinate + deltaLength )
            else
                selectedRange

        "remove" ->
            let
                -- With removal, we want to get the 1D coordinates against the old code, because that's the code we
                -- are erasing.
                ( deltaStartCoordinate, deltaEndCoordinate ) =
                    toOneDimensionalCoordinates oldCode deltaRange

                deltaLength =
                    deltaEndCoordinate - deltaStartCoordinate
            in
            if deltaEndCoordinate <= selectedStartCoordinate then
                fromOneDimensionalCoordinates newCode (shiftCoordinates (-1 * deltaLength) selectedCoordinates)
            else if deltaEndCoordinate <= selectedEndCoordinate then
                fromOneDimensionalCoordinates
                    newCode
                    ( Basics.min selectedStartCoordinate deltaStartCoordinate
                    , selectedEndCoordinate - deltaLength
                    )
            else
                fromOneDimensionalCoordinates
                    newCode
                    ( Basics.min selectedStartCoordinate deltaStartCoordinate
                    , Basics.min selectedEndCoordinate deltaStartCoordinate
                    )

        -- This will never happen, ACE actions are limited to "insert" and "remove", otherwise ACE errors internally
        -- and never sends it.
        _ ->
            selectedRange


{-| An empty range with every point on the origin.
-}
zeroRange : Range
zeroRange =
    Range 0 0 0 0
