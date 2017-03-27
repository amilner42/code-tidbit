module Models.BasicResponse exposing (..)

{-| -}


{-| To avoid worrying about handling empty responses, we use a basic object with a message always as opposed to an empty
http body.
-}
type alias BasicResponse =
    { message : String }
