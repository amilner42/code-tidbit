module JSON.TidbitPointer exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
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
    case tidbitType of
        Snipbit ->
            Encode.int 1

        Bigbit ->
            Encode.int 2


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
                    Decode.fail <| "That is not a valid encoded tidbitType: " ++ (toString encodedInt)
    in
        Decode.int
            |> Decode.andThen fromIntDecoder
