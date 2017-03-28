module JSON.IDResponse exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.IDResponse exposing (..)


{-| `CreateTidbitResponse` decoder.
-}
decoder : Decode.Decoder IDResponse
decoder =
    decode IDResponse
        |> required "targetID" Decode.string
