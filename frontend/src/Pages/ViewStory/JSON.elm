module Pages.ViewStory.JSON exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Pages.ViewStory.Model exposing (..)


{-| `ViewStory` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "maybeOpinion", Encode.null ) ]


{-| `ViewStory` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> hardcoded Nothing
