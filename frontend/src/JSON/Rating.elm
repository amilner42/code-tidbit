module JSON.Rating exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.Rating exposing (..)


{-| `Rating` encoder.

Parallels to the backend `Rating` enum.
-}
encoder : Rating -> Encode.Value
encoder =
    ratingToInt >> Encode.int


{-| `Rating` decoder.

Parallels to the backend `Rating` enum.
-}
decoder : Decode.Decoder Rating
decoder =
    let
        fromIntDecoder encodedInt =
            case encodedInt of
                1 ->
                    Decode.succeed Like

                _ ->
                    Decode.fail <| (toString encodedInt) ++ " is not a valid encoded rating!"
    in
        Decode.int |> Decode.andThen fromIntDecoder


{-| This maps exactly to the `Rating` enum on the backend.
-}
ratingToInt : Rating -> Int
ratingToInt rating =
    case rating of
        Like ->
            1
