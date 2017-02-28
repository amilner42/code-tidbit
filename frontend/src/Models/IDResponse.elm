module Models.IDResponse exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


{-| A basic response containing an ID.
-}
type alias IDResponse =
    { targetID : String
    }


{-| CreateTidbitResponse `decoder`.
-}
idResponseDecoder : Decode.Decoder IDResponse
idResponseDecoder =
    decode IDResponse
        |> required "targetID" Decode.string
