module JSON.Range exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Range exposing (..)


{-| `Range` encoder.
-}
encoder : Range -> Encode.Value
encoder record =
    Encode.object
        [ ( "startRow", Encode.int <| record.startRow )
        , ( "endRow", Encode.int <| record.endRow )
        , ( "startCol", Encode.int <| record.startCol )
        , ( "endCol", Encode.int <| record.endCol )
        ]


{-| `Range` decoder.
-}
decoder : Decode.Decoder Range
decoder =
    decode Range
        |> required "startRow" Decode.int
        |> required "endRow" Decode.int
        |> required "startCol" Decode.int
        |> required "endCol" Decode.int