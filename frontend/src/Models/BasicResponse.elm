module Models.BasicResponse exposing (BasicResponse, decoder)

import Json.Decode as Decode exposing (field)


{-| To avoid worrying about handling empty responses, we use a basic object
with a message always as opposed to an empty http body.
-}
type alias BasicResponse =
    { message : String }


{-| The BasicResponse `decoder`.
-}
decoder : Decode.Decoder BasicResponse
decoder =
    Decode.map BasicResponse
        (field "message" Decode.string)
