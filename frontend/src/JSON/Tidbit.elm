module JSON.Tidbit exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Bigbit as JSONBigbit
import JSON.Snipbit as JSONSnipbit
import Models.Tidbit exposing (..)


{-| `Tidbit` encoder.
-}
encoder : Tidbit -> Encode.Value
encoder tidbit =
    case tidbit of
        Snipbit snipbit ->
            JSONSnipbit.encoder snipbit

        Bigbit bigbit ->
            JSONBigbit.encoder bigbit


{-| `Tidbit` decodoer.
-}
decoder : Decode.Decoder Tidbit
decoder =
    let
        decodeSnipbit : Decode.Decoder Tidbit
        decodeSnipbit =
            Decode.map Snipbit JSONSnipbit.decoder

        decodeBigbit : Decode.Decoder Tidbit
        decodeBigbit =
            Decode.map Bigbit JSONBigbit.decoder
    in
        Decode.oneOf [ decodeSnipbit, decodeBigbit ]
