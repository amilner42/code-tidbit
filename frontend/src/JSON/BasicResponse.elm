module JSON.BasicResponse exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.BasicResponse exposing (..)


{-| `BasicResponse` decoder.
-}
decoder : Decode.Decoder BasicResponse
decoder =
    decode BasicResponse
        |> required "message" Decode.string
