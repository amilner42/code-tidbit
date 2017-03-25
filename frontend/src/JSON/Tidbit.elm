module JSON.Tidbit exposing (..)

import JSON.Bigbit
import JSON.Snipbit
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.Tidbit exposing (..)


{-| `Tidbit` encoder.
-}
encoder : Tidbit -> Encode.Value
encoder tidbit =
    case tidbit of
        Snipbit snipbit ->
            JSON.Snipbit.encoder snipbit

        Bigbit bigbit ->
            JSON.Bigbit.encoder bigbit


{-| `Tidbit` decodoer.
-}
decoder : Decode.Decoder Tidbit
decoder =
    let
        decodeSnipbit : Decode.Decoder Tidbit
        decodeSnipbit =
            Decode.map Snipbit JSON.Snipbit.decoder

        decodeBigbit : Decode.Decoder Tidbit
        decodeBigbit =
            Decode.map Bigbit JSON.Bigbit.decoder
    in
        Decode.oneOf [ decodeSnipbit, decodeBigbit ]
