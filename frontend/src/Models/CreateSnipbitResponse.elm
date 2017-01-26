module Models.CreateSnipbitResponse exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


{-| The ID of the new created tidbit.
-}
type alias CreateSnipbitResponse =
    { newID : String
    }


{-| CreateSnipbitResponse `decoder`.
-}
createSnipbitResponseDecoder : Decode.Decoder CreateSnipbitResponse
createSnipbitResponseDecoder =
    decode CreateSnipbitResponse
        |> required "newID" Decode.string
