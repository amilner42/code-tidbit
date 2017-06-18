module JSON.TidbitPointer exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Models.TidbitPointer exposing (..)


{-| `TidbitPointer` encoder.
-}
encoder : TidbitPointer -> Encode.Value
encoder tidbitPointer =
    Encode.object
        [ ( "tidbitType", tibitTypeEncoder tidbitPointer.tidbitType )
        , ( "targetID", Encode.string tidbitPointer.targetID )
        ]


{-| `TidbitPointer` decoder.
-}
decoder : Decode.Decoder TidbitPointer
decoder =
    decode TidbitPointer
        |> required "tidbitType" tidbitTypeDecoder
        |> required "targetID" Decode.string


{-| `TidbitType` encoder.

@NOTE This matches the backend format.

-}
tibitTypeEncoder : TidbitType -> Encode.Value
tibitTypeEncoder tidbitType =
    Encode.int <| tidbitTypeToInt tidbitType


{-| `TidbitType` decoder.

@NOTE This matches the backend format.

-}
tidbitTypeDecoder : Decode.Decoder TidbitType
tidbitTypeDecoder =
    let
        fromIntDecoder encodedInt =
            case encodedInt of
                1 ->
                    Decode.succeed Snipbit

                2 ->
                    Decode.succeed Bigbit

                _ ->
                    Decode.fail <| "That is not a valid encoded tidbitType: " ++ toString encodedInt
    in
    Decode.int
        |> Decode.andThen fromIntDecoder


{-| Converts a tidbitType to an int, matches the format of the backend.
-}
tidbitTypeToInt : TidbitType -> Int
tidbitTypeToInt tidbitType =
    case tidbitType of
        Snipbit ->
            1

        Bigbit ->
            2
