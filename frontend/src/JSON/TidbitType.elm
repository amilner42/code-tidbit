module JSON.TidbitType exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.TidbitType exposing (..)


{-| `TidbitType` encoder.
-}
encoder : TidbitType -> Encode.Value
encoder =
    toString >> Encode.string


{-| `TidbitType` decoder.
-}
decoder : Decode.Decoder TidbitType
decoder =
    let
        fromStringDecoder encodedTidbitType =
            case encodedTidbitType of
                "SnipBit" ->
                    Decode.succeed SnipBit

                "BigBit" ->
                    Decode.succeed BigBit

                _ ->
                    Decode.fail <| encodedTidbitType ++ " is not a valid encoded tidbit type."
    in
        Decode.string
            |> Decode.andThen fromStringDecoder
