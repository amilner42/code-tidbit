module Models.Tidbit exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Snipbit as SnipbitModel
import Models.Bigbit as BigbitModel


{-| All the different tidbit types.
-}
type Tidbit
    = Snipbit SnipbitModel.Snipbit
    | Bigbit BigbitModel.Bigbit


{-| Tidbit encoder.
-}
encoder : Tidbit -> Encode.Value
encoder tidbit =
    case tidbit of
        Snipbit snipbit ->
            SnipbitModel.snipbitEncoder snipbit

        Bigbit bigbit ->
            BigbitModel.bigbitEncoder bigbit


{-| Tidbit decodoer.
-}
decoder : Decode.Decoder Tidbit
decoder =
    let
        decodeSnipbit : Decode.Decoder Tidbit
        decodeSnipbit =
            Decode.map Snipbit SnipbitModel.snipbitDecoder

        decodeBigbit : Decode.Decoder Tidbit
        decodeBigbit =
            Decode.map Bigbit BigbitModel.bigbitDecoder
    in
        Decode.oneOf [ decodeSnipbit, decodeBigbit ]
