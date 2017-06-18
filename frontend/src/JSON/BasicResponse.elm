module JSON.BasicResponse exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Models.BasicResponse exposing (..)


{-| `BasicResponse` decoder.
-}
decoder : Decode.Decoder BasicResponse
decoder =
    decode BasicResponse
        |> required "message" Decode.string
