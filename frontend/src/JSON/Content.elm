module JSON.Content exposing (..)

import JSON.Bigbit
import JSON.Snipbit
import JSON.Story
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.Content exposing (..)


{-| `Content` decoder.
-}
decoder : Decode.Decoder Content
decoder =
    let
        decodeSnipbit : Decode.Decoder Content
        decodeSnipbit =
            Decode.map Snipbit JSON.Snipbit.decoder

        decodeBigbit : Decode.Decoder Content
        decodeBigbit =
            Decode.map Bigbit JSON.Bigbit.decoder

        decodeStory : Decode.Decoder Content
        decodeStory =
            Decode.map Story JSON.Story.decoder
    in
        Decode.oneOf [ decodeSnipbit, decodeBigbit, decodeStory ]
