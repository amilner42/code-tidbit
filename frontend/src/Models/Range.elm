module Models.Range exposing (..)

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
