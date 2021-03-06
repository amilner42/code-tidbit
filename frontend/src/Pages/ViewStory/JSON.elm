module Pages.ViewStory.JSON exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Pages.ViewStory.Model exposing (..)


{-| `ViewStory` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "possibleOpinion", Encode.null ) ]


{-| `ViewStory` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> hardcoded Nothing
