module JSON.ContentPointer exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.ContentPointer exposing (..)


{-| `ContentPointer` encoder.
-}
encoder : ContentPointer -> Encode.Value
encoder contentPointer =
    Encode.object
        [ ( "contentType", contentTypeEncoder contentPointer.contentType )
        , ( "contentID", Encode.string contentPointer.contentID )
        ]


{-| `ContentPointer` decoder.
-}
decoder : Decode.Decoder ContentPointer
decoder =
    decode ContentPointer
        |> required "contentType" contentTypeDecoder
        |> required "contentID" Decode.string


{-| `ContentType` encoder.

Parallel to backend `ContentType` enum.
-}
contentTypeEncoder : ContentType -> Encode.Value
contentTypeEncoder =
    contentTypeToInt >> Encode.int


{-| `ContentType` decoder.

Parallel to backend `ContentType` enum.
-}
contentTypeDecoder : Decode.Decoder ContentType
contentTypeDecoder =
    let
        fromIntDecoder encodedInt =
            case encodedInt of
                1 ->
                    Decode.succeed Snipbit

                2 ->
                    Decode.succeed Bigbit

                3 ->
                    Decode.succeed Story

                _ ->
                    Decode.fail <| (toString encodedInt) ++ " is not a valid encoded content type!"
    in
        Decode.int |> Decode.andThen fromIntDecoder


{-| This maps exactly to the `ContentType` enum on the backend.
-}
contentTypeToInt : ContentType -> Int
contentTypeToInt contentType =
    case contentType of
        Snipbit ->
            1

        Bigbit ->
            2

        Story ->
            3
