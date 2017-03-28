module JSON.BasicResponse exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.BasicResponse exposing (..)


{-| `BasicResponse` decoder.
-}
decoder : Decode.Decoder BasicResponse
decoder =
    decode BasicResponse
        |> required "message" Decode.string
