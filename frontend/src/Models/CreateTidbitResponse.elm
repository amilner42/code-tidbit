module Models.CreateTidbitResponse exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


-- TODO rename from "CreateTidbitResponse" to `idResponse` or something more
-- general.


{-| The ID of the new created tidbit.
-}
type alias CreateTidbitResponse =
    { newID : String
    }


{-| CreateTidbitResponse `decoder`.
-}
createTidbitResponseDecoder : Decode.Decoder CreateTidbitResponse
createTidbitResponseDecoder =
    decode CreateTidbitResponse
        |> required "newID" Decode.string
