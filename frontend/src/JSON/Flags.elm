module JSON.Flags exposing (..)

import Flags exposing (Flags)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode


{-| `Flags` encoder.
-}
encoder : Flags -> Encode.Value
encoder flags =
    Encode.object
        [ ( "apiBaseUrl", Encode.string flags.apiBaseUrl )
        ]


{-| `Flags` decoder.
-}
decoder : Decode.Decoder Flags
decoder =
    decode Flags
        |> required "apiBaseUrl" Decode.string
