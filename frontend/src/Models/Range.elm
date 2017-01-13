module Models.Range exposing (..)

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
